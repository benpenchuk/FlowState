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

final class ActiveWorkoutViewModel: ObservableObject {
    @Published var activeWorkout: Workout?
    @Published var elapsedTime: TimeInterval = 0
    @Published var detectedPR: PersonalRecord? = nil // PR detected when set is completed
    
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var progressViewModel: ProgressViewModel?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        progressViewModel = ProgressViewModel()
        progressViewModel?.setModelContext(context)
        loadActiveWorkout()
        startTimer()
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
            updateElapsedTime()
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
    
    func finishWorkout() {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        workout.completedAt = Date()
        
        do {
            try modelContext.save()
            activeWorkout = nil
            stopTimer()
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
            stopTimer()
        } catch {
            print("Error canceling workout: \(error)")
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard let workout = activeWorkout else {
            elapsedTime = 0
            return
        }
        elapsedTime = Date().timeIntervalSince(workout.startedAt)
    }
    
    deinit {
        stopTimer()
    }
}
