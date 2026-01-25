//
//  HistoryViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class HistoryViewModel: ObservableObject {
    @Published var completedWorkouts: [Workout] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchCompletedWorkouts()
    }
    
    func fetchCompletedWorkouts() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            completedWorkouts = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching completed workouts: \(error)")
            completedWorkouts = []
        }
        
        isLoading = false
    }
    
    func deleteWorkout(_ workout: Workout) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(workout)
        
        do {
            try modelContext.save()
            fetchCompletedWorkouts()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
    
    func groupWorkoutsByDate() -> [(String, [Workout])] {
        let calendar = Calendar.current
        var grouped: [String: [Workout]] = [:]
        
        for workout in completedWorkouts {
            guard let completedAt = workout.completedAt else { continue }
            
            let dateKey: String
            if calendar.isDateInToday(completedAt) {
                dateKey = "Today"
            } else if calendar.isDateInYesterday(completedAt) {
                dateKey = "Yesterday"
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                      completedAt >= weekAgo {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE" // Day name
                dateKey = formatter.string(from: completedAt)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                dateKey = formatter.string(from: completedAt)
            }
            
            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(workout)
        }
        
        // Sort keys: Today, Yesterday, then days of week, then months
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            if key1 == "Today" { return true }
            if key2 == "Today" { return false }
            if key1 == "Yesterday" { return true }
            if key2 == "Yesterday" { return false }
            
            // Get the first workout's date for each key to sort
            let date1 = grouped[key1]?.first?.completedAt ?? Date.distantPast
            let date2 = grouped[key2]?.first?.completedAt ?? Date.distantPast
            return date1 > date2
        }
        
        return sortedKeys.compactMap { key in
            guard let workouts = grouped[key] else { return nil }
            return (key, workouts)
        }
    }
    
    func calculateDuration(startedAt: Date, completedAt: Date) -> TimeInterval {
        return completedAt.timeIntervalSince(startedAt)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
    
    func countCompletedSets(in workout: Workout) -> Int {
        guard let entries = workout.entries else { return 0 }
        
        var totalCompleted = 0
        for entry in entries {
            let sets = entry.getSets()
            totalCompleted += sets.filter { $0.isCompleted }.count
        }
        return totalCompleted
    }
    
    // Format volume with units conversion and abbreviated notation
    func formatVolume(_ volumeInLbs: Double?, preferredUnits: Units) -> String? {
        guard let volume = volumeInLbs, volume > 0 else { return nil }
        
        let displayVolume = preferredUnits == .kg ? volume / 2.20462 : volume
        let unit = preferredUnits == .kg ? "kg" : "lbs"
        
        // Use abbreviated formatter (e.g., 16.2k, 1.5M)
        return "\(displayVolume.abbreviated()) \(unit)"
    }
    
    // Format workout for export as shareable text
    func formatWorkoutForExport(_ workout: Workout, preferredUnits: Units = .lbs) -> String {
        var text = "💪 "
        text += (workout.name ?? "Workout")
        
        if let completedAt = workout.completedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            text += " - \(formatter.string(from: completedAt))"
        }
        text += "\n\n"
        
        guard let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty else {
            return text + "No exercises"
        }
        
        for entry in entries {
            let exerciseName = entry.exercise?.name ?? "Unknown Exercise"
            text += "\(exerciseName)\n"
            
            let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
            for set in sets {
                if set.isCompleted {
                    // Add label if present
                    var setText = "  Set \(set.setNumber)"
                    if set.label != .none {
                        setText += " (\(set.label.rawValue))"
                    }
                    setText += ": "
                    
                    if let weight = set.weight, let reps = set.reps {
                        let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
                        let unit = preferredUnits == .kg ? "kg" : "lbs"
                        let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", displayWeight) : String(format: "%.1f", displayWeight)
                        setText += "\(weightStr) \(unit) × \(reps) reps ✓"
                    } else if let reps = set.reps {
                        setText += "\(reps) reps ✓"
                    } else {
                        setText += "✓"
                    }
                    text += setText + "\n"
                }
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                text += "  Notes: \(notes)\n"
            }
            
            text += "\n"
        }
        
        if let completedAt = workout.completedAt {
            let duration = calculateDuration(startedAt: workout.startedAt, completedAt: completedAt)
            text += "Duration: \(formatDuration(duration))\n"
        }
        
        if let notes = workout.notes, !notes.isEmpty {
            text += "Notes: \(notes)\n"
        }
        
        text += "\nFlowState - Find Your Flow"
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
