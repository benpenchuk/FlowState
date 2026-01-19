//
//  HomeStatsViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

enum StatsPeriod: String, CaseIterable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
}

@MainActor
final class HomeStatsViewModel: ObservableObject {
    @Published var workoutsCount: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var previousWorkoutsCount: Int = 0
    @Published var previousTotalTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    @Published var selectedPeriod: StatsPeriod = .last7Days
    @Published var last7DaysActivity: [Bool] = Array(repeating: false, count: 7)
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe period changes and recalculate stats
        $selectedPeriod
            .dropFirst()
            .sink { [weak self] period in
                Task { @MainActor in
                    await self?.calculateStats(for: period)
                }
            }
            .store(in: &cancellables)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await calculateStats(for: selectedPeriod)
        }
    }
    
    func refreshStats() {
        Task {
            await calculateStats(for: selectedPeriod)
        }
    }
    
    func calculateStats(for period: StatsPeriod) async {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let (startDate, endDate) = self.getDateRange(for: period)
            let (prevStartDate, prevEndDate) = self.getPreviousDateRange(for: period)
            
            // Calculate current period stats
            let currentStats = self.calculatePeriodStats(
                modelContext: modelContext,
                startDate: startDate,
                endDate: endDate
            )
            
            // Calculate previous period stats for comparison
            let previousStats = self.calculatePeriodStats(
                modelContext: modelContext,
                startDate: prevStartDate,
                endDate: prevEndDate
            )
            
            // Calculate streak (always current)
            let streak = self.calculateStreakSync(modelContext: modelContext)
            
            // Calculate activity dots for last 7 days
            let activity = self.calculateLast7DaysActivity(modelContext: modelContext)
            
            // Update on main actor
            await MainActor.run {
                self.workoutsCount = currentStats.count
                self.totalTime = currentStats.time
                self.currentStreak = streak
                self.last7DaysActivity = activity
                self.previousWorkoutsCount = previousStats.count
                self.previousTotalTime = previousStats.time
                self.isLoading = false
                
                print("📊 Stats calculated: \(currentStats.count) workouts, \(Int(currentStats.time/60)) minutes")
            }
        }.value
    }
    
    nonisolated private func calculatePeriodStats(
        modelContext: ModelContext,
        startDate: Date,
        endDate: Date
    ) -> (count: Int, time: TimeInterval) {
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let allCompletedWorkouts = try modelContext.fetch(workoutDescriptor)
            
            // Filter workouts in the date range
            let workoutsInPeriod = allCompletedWorkouts.filter { workout in
                guard let completedAt = workout.completedAt else { return false }
                return completedAt >= startDate && completedAt <= endDate
            }
            
            var totalTime: TimeInterval = 0
            
            for workout in workoutsInPeriod {
                if let completedAt = workout.completedAt {
                    totalTime += completedAt.timeIntervalSince(workout.startedAt)
                }
            }
            
            return (workoutsInPeriod.count, totalTime)
        } catch {
            print("Error calculating period stats: \(error)")
            return (0, 0)
        }
    }
    
    nonisolated private func calculateStreakSync(modelContext: ModelContext) -> Int {
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
    
    nonisolated private func calculateLast7DaysActivity(modelContext: ModelContext) -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var activity = [Bool]()
        
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt != nil
            }
        )
        
        do {
            let completedWorkouts = try modelContext.fetch(workoutDescriptor)
            let workoutDates = Set(completedWorkouts.compactMap { $0.completedAt.map { calendar.startOfDay(for: $0) } })
            
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    activity.append(workoutDates.contains(date))
                } else {
                    activity.append(false)
                }
            }
            
            return activity.reversed() // Oldest to newest (today)
        } catch {
            return Array(repeating: false, count: 7)
        }
    }
    
    nonisolated func getDateRange(for period: StatsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = now
        
        switch period {
        case .last7Days:
            // Last 7 days from now
            guard let start = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else {
                return (now, now)
            }
            return (start, endDate)
            
        case .last30Days:
            // Last 30 days from now
            guard let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else {
                return (now, now)
            }
            return (start, endDate)
        }
    }
    
    nonisolated func getPreviousDateRange(for period: StatsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let (currentStart, _) = getDateRange(for: period)
        
        switch period {
        case .last7Days:
            // Previous 7 days (days 8-14 before now)
            guard let prevEnd = calendar.date(byAdding: .second, value: -1, to: currentStart),
                  let prevStart = calendar.date(byAdding: .day, value: -7, to: currentStart) else {
                return (currentStart, currentStart)
            }
            return (prevStart, prevEnd)
            
        case .last30Days:
            // Previous 30 days (days 31-60 before now)
            guard let prevEnd = calendar.date(byAdding: .second, value: -1, to: currentStart),
                  let prevStart = calendar.date(byAdding: .day, value: -30, to: currentStart) else {
                return (currentStart, currentStart)
            }
            return (prevStart, prevEnd)
        }
    }
}
