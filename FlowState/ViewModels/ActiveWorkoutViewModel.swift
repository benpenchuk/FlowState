//
//  ActiveWorkoutViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

enum ActiveWorkoutField {
    case weight, reps
}

final class ActiveWorkoutViewModel: ObservableObject {
    @Published var activeWorkout: Workout? {
        didSet {
            // Collapse state is per active workout session.
            // Reset when switching to a different workout.
            if oldValue?.id != activeWorkout?.id {
                collapsedEntryIds.removeAll()
            }
        }
    }
    @Published var detectedPR: PersonalRecord? = nil // PR detected when set is completed
    @Published var focusedSetId: UUID? = nil
    @Published var focusedField: ActiveWorkoutField? = nil
    @Published var scrollToSetId: UUID? = nil
    @Published private(set) var collapsedEntryIds: Set<UUID> = []
    
    private var modelContext: ModelContext?
    private var progressViewModel: ProgressViewModel?

    func isEntryCollapsed(_ entryId: UUID) -> Bool {
        collapsedEntryIds.contains(entryId)
    }

    func toggleEntryCollapsed(_ entryId: UUID) {
        if collapsedEntryIds.contains(entryId) {
            collapsedEntryIds.remove(entryId)
        } else {
            collapsedEntryIds.insert(entryId)
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        progressViewModel = ProgressViewModel()
        progressViewModel?.setModelContext(context)
        loadActiveWorkout()
    }
    
    func refreshActiveWorkout() {
        loadActiveWorkout()
    }
    
    private func loadActiveWorkout() {
        guard let modelContext = modelContext else { return }
        
        // Find workout that's in progress (has startedAt but no completedAt)
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt == nil
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            activeWorkout = workouts.first
        } catch {
            print("Error loading active workout: \(error)")
            activeWorkout = nil
        }
    }
    
    func hasActiveWorkout() -> Bool {
        guard let modelContext = modelContext else { return false }
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt == nil
            }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            return !workouts.isEmpty
        } catch {
            return false
        }
    }
    
    func startWorkoutFromTemplate(_ template: WorkoutTemplate, discardExisting: Bool = false) {
        guard let modelContext = modelContext else { return }
        
        // Check for existing workout and handle if needed
        if !discardExisting && hasActiveWorkout() {
            return // Should be handled by caller with alert
        }
        
        // Delete existing active workout if discarding
        if discardExisting {
            let descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.completedAt == nil
                }
            )
            
            do {
                let existing = try modelContext.fetch(descriptor)
                for workout in existing {
                    modelContext.delete(workout)
                }
                try? modelContext.save()
            } catch {
                print("Error deleting existing workout: \(error)")
            }
        }
        
        let workout = Workout(
            name: template.name,
            startedAt: Date(),
            completedAt: nil
        )
        modelContext.insert(workout)
        
        var entries: [WorkoutEntry] = []
        if let templateExercises = template.exercises?.sorted(by: { $0.order < $1.order }) {
            for (index, templateExercise) in templateExercises.enumerated() {
                guard let exercise = templateExercise.exercise else { continue }
                
                let entry = WorkoutEntry(
                    exercise: exercise,
                    order: index,
                    sets: [],
                    workout: workout
                )
                
                // Pre-populate with default sets from template
                var defaultSets: [SetRecord] = []
                for setNum in 1...templateExercise.defaultSets {
                    let setRecord = SetRecord(
                        setNumber: setNum,
                        reps: templateExercise.defaultReps,
                        weight: templateExercise.defaultWeight,
                        isCompleted: false
                    )
                    defaultSets.append(setRecord)
                }
                entry.setSets(defaultSets)
                
                entry.workout = workout
                entries.append(entry)
                modelContext.insert(entry)
            }
        }
        
        workout.entries = entries
        
        do {
            try modelContext.save()
            activeWorkout = workout
            template.lastUsedAt = Date()
            try? modelContext.save()
            print("✅ Workout started successfully: \(workout.name ?? "Unnamed")")
        } catch {
            print("❌ Error starting workout: \(error)")
        }
    }
    
    func startEmptyWorkout(name: String? = nil, discardExisting: Bool = false) {
        guard let modelContext = modelContext else { return }
        
        // Check for existing workout and handle if needed
        if !discardExisting && hasActiveWorkout() {
            return // Should be handled by caller with alert
        }
        
        // Delete existing active workout if discarding
        if discardExisting {
            let descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.completedAt == nil
                }
            )
            
            do {
                let existing = try modelContext.fetch(descriptor)
                for workout in existing {
                    modelContext.delete(workout)
                }
                try? modelContext.save()
            } catch {
                print("Error deleting existing workout: \(error)")
            }
        }
        
        let workout = Workout(
            name: name,
            startedAt: Date(),
            completedAt: nil
        )
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
            activeWorkout = workout
        } catch {
            print("Error starting workout: \(error)")
        }
    }
    
    func addExerciseToWorkout(_ exercise: Exercise) {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        let maxOrder = workout.entries?.map { $0.order }.max() ?? -1
        let entry = WorkoutEntry(
            exercise: exercise,
            order: maxOrder + 1,
            sets: [],
            workout: workout
        )
        
        entry.workout = workout
        
        if workout.entries == nil {
            workout.entries = []
        }
        workout.entries?.append(entry)
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Error adding exercise to workout: \(error)")
        }
    }
    
    func addSetToEntry(_ entry: WorkoutEntry) {
        guard let modelContext = modelContext else { return }
        
        var sets = entry.getSets()
        let nextSetNumber = sets.count + 1
        let newSet = SetRecord(
            setNumber: nextSetNumber,
            reps: nil,
            weight: nil,
            isCompleted: false
        )
        sets.append(newSet)
        entry.setSets(sets)
        
        do {
            try modelContext.save()
        } catch {
            print("Error adding set: \(error)")
        }
    }
    
    func updateSet(in entry: WorkoutEntry, set: SetRecord, reps: Int?, weight: Double?, isCompleted: Bool) {
        guard let modelContext = modelContext else { return }
        
        var sets = entry.getSets()
        if let index = sets.firstIndex(where: { $0.id == set.id }) {
            let wasCompleted = sets[index].isCompleted
            sets[index].reps = reps
            sets[index].weight = weight
            sets[index].isCompleted = isCompleted
            
            // Set completedAt timestamp when set is marked complete
            if !wasCompleted && isCompleted {
                sets[index].completedAt = Date()
            } else if wasCompleted && !isCompleted {
                // Clear timestamp if set is unmarked
                sets[index].completedAt = nil
            }
            
            entry.setSets(sets)
            
            do {
                try modelContext.save()
                
                // Check for PR if set was just completed
                if !wasCompleted && isCompleted, let exercise = entry.exercise {
                    if let newPR = progressViewModel?.detectNewPR(
                        exercise: exercise,
                        weight: weight,
                        reps: reps,
                        workout: activeWorkout
                    ) {
                        detectedPR = newPR
                        // Clear PR notification after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            self?.detectedPR = nil
                        }
                    }
                }
            } catch {
                print("Error updating set: \(error)")
            }
        }
    }
    
    func autoAdvance(from entry: WorkoutEntry, completedSet: SetRecord) {
        guard let workout = activeWorkout else { return }
        
        // 1. Try to find the next incomplete set in the CURRENT entry
        let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
        if let nextIncomplete = sets.first(where: { !$0.isCompleted && $0.setNumber > completedSet.setNumber }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scrollToSetId = nextIncomplete.id
            }
            return
        }
        
        // 2. If all sets in current entry are done, try the next entry
        if let entries = workout.entries?.sorted(by: { $0.order < $1.order }) {
            if let currentEntryIndex = entries.firstIndex(where: { $0.id == entry.id }),
               currentEntryIndex + 1 < entries.count {
                let nextEntry = entries[currentEntryIndex + 1]
                let nextSets = nextEntry.getSets().sorted { $0.setNumber < $1.setNumber }
                if let firstIncomplete = nextSets.first(where: { !$0.isCompleted }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        scrollToSetId = firstIncomplete.id
                    }
                }
            }
        }
    }
    
    func getLastSessionSets(for exercise: Exercise) -> [SetRecord] {
        guard let modelContext = modelContext else { return [] }
        
        // Fetch recent completed workouts
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            
            // Look for the most recent workout that contains this exercise
            for workout in workouts {
                guard let entries = workout.entries else { continue }
                
                // Find all entries for this exercise in this workout (in case of supersets/multiple entries)
                let matchingEntries = entries.filter { entry in
                    if let entryExercise = entry.exercise {
                        return entryExercise.id == exercise.id || entryExercise.name == exercise.name
                    }
                    return false
                }.sorted { $0.order < $1.order }
                
                if !matchingEntries.isEmpty {
                    // Combine sets from all matching entries in this workout
                    var allSets: [SetRecord] = []
                    for entry in matchingEntries {
                        allSets.append(contentsOf: entry.getSets())
                    }
                    
                    // Return only completed sets, sorted by their original set numbers
                    return allSets.filter { $0.isCompleted }
                        .sorted { $0.setNumber < $1.setNumber }
                }
            }
        } catch {
            print("Error fetching last session sets: \(error)")
        }
        
        return []
    }
    
    func removeSet(from entry: WorkoutEntry, set: SetRecord) {
        guard let modelContext = modelContext else { return }
        
        var sets = entry.getSets()
        sets.removeAll { $0.id == set.id }
        
        // Renumber remaining sets
        for index in sets.indices {
            sets[index].setNumber = index + 1
        }
        
        entry.setSets(sets)
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing set: \(error)")
        }
    }
    
    func deleteSet(from entry: WorkoutEntry, at index: Int) {
        guard let modelContext = modelContext else { return }
        
        var sets = entry.getSets()
        guard index < sets.count else { return }
        sets.remove(at: index)
        
        // Renumber remaining sets
        for index in sets.indices {
            sets[index].setNumber = index + 1
        }
        
        if sets.isEmpty {
            // Last set deleted, remove exercise
            deleteExercise(entry)
        } else {
            entry.setSets(sets)
            do {
                try modelContext.save()
            } catch {
                print("Error deleting set: \(error)")
            }
        }
    }
    
    func deleteExercise(_ entry: WorkoutEntry) {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        workout.entries?.removeAll { $0.id == entry.id }
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }

    /// Persist set order by `SetRecord.id` and renumber `setNumber` to 1...N.
    func applySetOrder(in entry: WorkoutEntry, orderedSetIds: [UUID]) {
        guard let modelContext = modelContext else { return }

        let existingSets = entry.getSets()
        guard !existingSets.isEmpty else { return }

        let setsById = Dictionary(uniqueKeysWithValues: existingSets.map { ($0.id, $0) })

        // Build ordered list from IDs first.
        var reordered: [SetRecord] = orderedSetIds.compactMap { setsById[$0] }

        // Safety: append any sets not represented in `orderedSetIds`.
        if reordered.count != existingSets.count {
            let existingIdSet = Set(existingSets.map(\.id))
            let orderedIdSet = Set(orderedSetIds)
            let missingIds = existingIdSet.subtracting(orderedIdSet)
            reordered.append(contentsOf: existingSets.filter { missingIds.contains($0.id) })
        }

        // Renumber.
        for idx in reordered.indices {
            reordered[idx].setNumber = idx + 1
        }

        entry.setSets(reordered)

        do {
            try modelContext.save()
        } catch {
            print("Error applying set order: \(error)")
        }
    }
    
    func reorderSets(in entry: WorkoutEntry, from source: IndexSet, to destination: Int) {
        print("🔄 reorderSets CALLED - Source: \(source), Destination: \(destination)")
        guard let modelContext = modelContext else {
            print("🔴 No modelContext available")
            return
        }
        
        var sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
        print("🔄 Sets before move: \(sets.map { ($0.setNumber, $0.id) })")
        print("🔄 Moving from offsets: \(Array(source)), to offset: \(destination)")
        
        sets.move(fromOffsets: source, toOffset: destination)
        
        print("🔄 Sets after move: \(sets.map { ($0.setNumber, $0.id) })")
        
        // Renumber sets to match new order
        for (index, _) in sets.enumerated() {
            sets[index].setNumber = index + 1
        }
        
        print("🔄 Sets after renumbering: \(sets.map { ($0.setNumber, $0.id) })")
        
        entry.setSets(sets)
        
        do {
            try modelContext.save()
            print("✅ Sets reordered and saved successfully")
        } catch {
            print("🔴 Error reordering sets: \(error)")
        }
    }
    
    func updateSetLabel(in entry: WorkoutEntry, set: SetRecord, label: SetLabel) {
        guard let modelContext = modelContext else { return }
        
        var sets = entry.getSets()
        if let index = sets.firstIndex(where: { $0.id == set.id }) {
            sets[index].label = label
            entry.setSets(sets)
            
            do {
                try modelContext.save()
            } catch {
                print("Error updating set label: \(error)")
            }
        }
    }
    
    func updateExerciseNotes(in entry: WorkoutEntry, notes: String?) {
        guard let modelContext = modelContext else { return }
        
        entry.notes = notes
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating exercise notes: \(error)")
        }
    }
    
    func finishWorkout() {
        finishWorkout(effortRating: nil, notes: nil)
    }
    
    func finishWorkout(effortRating: Int?, notes: String?) {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        workout.completedAt = Date()
        workout.effortRating = effortRating
        workout.notes = notes
        
        // Calculate total volume (sum of weight × reps for all completed sets with weight > 0)
        var totalVolume: Double = 0
        if let entries = workout.entries {
            for entry in entries {
                let sets = entry.getSets()
                for set in sets {
                    if set.isCompleted, let weight = set.weight, weight > 0, let reps = set.reps {
                        totalVolume += weight * Double(reps)
                    }
                }
            }
        }
        workout.totalVolume = totalVolume > 0 ? totalVolume : nil
        
        do {
            try modelContext.save()
            activeWorkout = nil
        } catch {
            print("Error finishing workout: \(error)")
        }
    }
    
    func cancelWorkout() {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        modelContext.delete(workout)
        
        do {
            try modelContext.save()
            activeWorkout = nil
        } catch {
            print("Error canceling workout: \(error)")
        }
    }
}
