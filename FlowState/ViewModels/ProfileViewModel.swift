//
//  ProfileViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import Combine

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var totalWorkouts: Int = 0
    @Published var totalPRs: Int = 0
    @Published var currentStreak: Int = 0
    @Published var totalVolume: Double = 0 // Total volume in lbs across all workouts
    @Published var recentPRs: [PersonalRecord] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProfile()
        calculateStats()
    }
    
    private func loadProfile() {
        guard let modelContext = modelContext else { return }
        
        // Fetch or create the single UserProfile instance
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let existingProfile = profiles.first {
                profile = existingProfile
            } else {
                // Create new profile
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                try modelContext.save()
                profile = newProfile
            }
        } catch {
            print("Error loading profile: \(error)")
            // Create default profile if fetch fails
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            try? modelContext.save()
            profile = newProfile
        }
    }
    
    func calculateStats() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        // Total workouts completed
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            }
        )
        
        do {
            let completedWorkouts = try modelContext.fetch(workoutDescriptor)
            totalWorkouts = completedWorkouts.count
            
            // Total volume (sum of totalVolume across all completed workouts)
            totalVolume = completedWorkouts.compactMap { $0.totalVolume }.reduce(0, +)
        } catch {
            print("Error fetching workouts: \(error)")
            totalWorkouts = 0
            totalVolume = 0
        }
        
        // Total PRs
        let prDescriptor = FetchDescriptor<PersonalRecord>()
        
        do {
            let prs = try modelContext.fetch(prDescriptor)
            totalPRs = prs.count
        } catch {
            print("Error fetching PRs: \(error)")
            totalPRs = 0
        }
        
        // Current streak (consecutive days with completed workouts)
        currentStreak = calculateStreak()
        
        // Recent PRs (last 3)
        loadRecentPRs(limit: 3)
        
        isLoading = false
    }
    
    private func calculateStreak() -> Int {
        guard let modelContext = modelContext else { return 0 }
        
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            }
        )
        
        do {
            let completedWorkouts = try modelContext.fetch(workoutDescriptor)
            guard !completedWorkouts.isEmpty else { return 0 }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Get unique workout dates
            var workoutDates = Set<Date>()
            for workout in completedWorkouts {
                guard let completedAt = workout.completedAt else { continue }
                workoutDates.insert(calendar.startOfDay(for: completedAt))
            }
            
            // Calculate streak starting from today
            var streak = 0
            var checkDate = today
            
            // Check if today has a workout
            if workoutDates.contains(checkDate) {
                streak = 1
            } else {
                // If no workout today, check yesterday
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                if workoutDates.contains(checkDate) {
                    streak = 1
                } else {
                    return 0 // No streak if no workout today or yesterday
                }
            }
            
            // Continue checking previous days
            while true {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                if workoutDates.contains(checkDate) {
                    streak += 1
                } else {
                    break // Gap found, streak ends
                }
            }
            
            return streak
        } catch {
            print("Error calculating streak: \(error)")
            return 0
        }
    }
    
    private func loadRecentPRs(limit: Int) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            let allPRs = try modelContext.fetch(descriptor)
            recentPRs = Array(allPRs.prefix(limit))
        } catch {
            print("Error fetching recent PRs: \(error)")
            recentPRs = []
        }
    }
    
    func updateName(_ newName: String) {
        guard let profile = profile, let modelContext = modelContext else { return }
        profile.name = newName.isEmpty ? "Athlete" : newName
        try? modelContext.save()
    }
    
    func updatePreferredUnits(_ units: Units) {
        guard let profile = profile, let modelContext = modelContext else { return }
        profile.units = units
        try? modelContext.save()
    }
    
    func updateDefaultRestTime(_ seconds: Int) {
        guard let profile = profile, let modelContext = modelContext else { return }
        profile.defaultRestTime = seconds
        try? modelContext.save()
    }
    
    func updateAppearanceMode(_ mode: AppearanceMode) {
        guard let profile = profile, let modelContext = modelContext else { return }
        profile.appearance = mode
        try? modelContext.save()
    }
    
    func refreshStats() {
        calculateStats()
    }
}
