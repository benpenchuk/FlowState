//
//  ProgressViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import Combine

final class ProgressViewModel: ObservableObject {
    @Published var recentPRs: [PersonalRecord] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRecentPRs()
    }
    
    // MARK: - PR Detection
    
    /// Get all completed sets for a specific exercise across all workouts
    func getAllCompletedSets(for exercise: Exercise) -> [(SetRecord, Date)] {
        guard let modelContext = modelContext else { return [] }
        
        // Fetch all completed workouts that contain this exercise
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            var allSets: [(SetRecord, Date)] = []
            
            for workout in workouts {
                guard let entries = workout.entries else { continue }
                
                for entry in entries {
                    if entry.exercise?.id == exercise.id {
                        let sets = entry.getSets()
                        let workoutDate = workout.completedAt ?? workout.startedAt
                        
                        for set in sets where set.isCompleted {
                            allSets.append((set, workoutDate))
                        }
                    }
                }
            }
            
            return allSets
        } catch {
            print("Error fetching completed sets: \(error)")
            return []
        }
    }
    
    /// Calculate PR (personal record) for an exercise - highest weight lifted for at least 1 rep
    func calculatePR(for exercise: Exercise) -> PersonalRecord? {
        guard let modelContext = modelContext else { return nil }
        
        // Fetch all PRs and filter in memory (avoids predicate UUID comparison issues)
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.weight, order: .reverse), SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            let allPRs = try modelContext.fetch(descriptor)
            // Filter for this exercise and return the highest weight PR
            let exercisePRs = allPRs.filter { $0.exercise?.id == exercise.id }
            return exercisePRs.first
        } catch {
            print("Error fetching PR: \(error)")
            return nil
        }
    }
    
    /// Calculate PR on-the-fly from all completed sets (alternative method)
    func calculatePRFromSets(for exercise: Exercise) -> (weight: Double, reps: Int, date: Date)? {
        let allSets = getAllCompletedSets(for: exercise)
        
        guard !allSets.isEmpty else { return nil }
        
        // Find the set with highest weight (for at least 1 rep)
        var maxWeight: Double = 0
        var maxReps: Int = 0
        var maxDate: Date = Date()
        
        for (set, date) in allSets {
            if let weight = set.weight, let reps = set.reps, reps >= 1 {
                if weight > maxWeight {
                    maxWeight = weight
                    maxReps = reps
                    maxDate = date
                }
            }
        }
        
        guard maxWeight > 0 else { return nil }
        
        return (maxWeight, maxReps, maxDate)
    }
    
    /// Detect if a just-completed set is a new PR
    func detectNewPR(exercise: Exercise, weight: Double?, reps: Int?, workout: Workout?) -> PersonalRecord? {
        guard let modelContext = modelContext,
              let weight = weight,
              let reps = reps,
              reps >= 1,
              weight > 0 else {
            return nil
        }
        
        // Get current PR for this exercise
        let currentPR = calculatePR(for: exercise)
        
        // Check if this is a new PR (higher weight)
        let isNewPR: Bool
        if let currentPR = currentPR {
            isNewPR = weight > currentPR.weight
        } else {
            // No existing PR, so this is automatically a PR
            isNewPR = true
        }
        
        if isNewPR {
            // Create and save new PR
            let newPR = PersonalRecord(
                exercise: exercise,
                weight: weight,
                reps: reps,
                achievedAt: Date(),
                workout: workout
            )
            
            modelContext.insert(newPR)
            
            do {
                try modelContext.save()
                loadRecentPRs() // Refresh recent PRs
                return newPR
            } catch {
                print("Error saving PR: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    /// Get recent PRs (last 7 days)
    func getRecentPRs(days: Int = 7) -> [PersonalRecord] {
        guard let modelContext = modelContext else { return [] }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { pr in
                pr.achievedAt >= cutoffDate
            },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching recent PRs: \(error)")
            return []
        }
    }
    
    private func loadRecentPRs() {
        isLoading = true
        recentPRs = getRecentPRs()
        isLoading = false
    }
    
    /// Get exercise history (last N times performed)
    func getExerciseHistory(for exercise: Exercise, limit: Int = 10) -> [(date: Date, maxWeight: Double, sets: [SetRecord])] {
        guard let modelContext = modelContext else { return [] }
        
        // Fetch all completed workouts containing this exercise
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            var history: [(date: Date, maxWeight: Double, sets: [SetRecord])] = []
            
            for workout in workouts {
                guard let entries = workout.entries else { continue }
                
                for entry in entries {
                    if entry.exercise?.id == exercise.id {
                        let sets = entry.getSets().filter { $0.isCompleted }
                        
                        guard !sets.isEmpty else { continue }
                        
                        // Find max weight in this workout session
                        let maxWeight = sets.compactMap { $0.weight }.max() ?? 0
                        let workoutDate = workout.completedAt ?? workout.startedAt
                        
                        history.append((workoutDate, maxWeight, sets))
                        
                        if history.count >= limit {
                            return history
                        }
                        
                        break // Only count once per workout
                    }
                }
            }
            
            return history
        } catch {
            print("Error fetching exercise history: \(error)")
            return []
        }
    }
    
    /// Get weight progression data for chart (date, max weight)
    func getWeightProgression(for exercise: Exercise) -> [(date: Date, weight: Double)] {
        let history = getExerciseHistory(for: exercise, limit: 100) // Get more data for chart
        
        return history.map { (date: $0.date, weight: $0.maxWeight) }
            .sorted { $0.date < $1.date } // Sort by date ascending
    }
}
