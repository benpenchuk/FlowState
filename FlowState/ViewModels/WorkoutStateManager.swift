//
//  WorkoutStateManager.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class WorkoutStateManager: ObservableObject {
    @Published var activeWorkout: Workout? = nil
    @Published var isWorkoutFullScreen: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    
    private var modelContext: ModelContext?
    nonisolated(unsafe) private var timer: Timer?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadActiveWorkout()
        startTimer()
    }
    
    private func loadActiveWorkout() {
        guard let modelContext = modelContext else { return }
        
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
    
    func refreshActiveWorkout() {
        loadActiveWorkout()
    }
    
    func hasActiveWorkout() -> Bool {
        return activeWorkout != nil
    }
    
    func setActiveWorkout(_ workout: Workout) {
        activeWorkout = workout
        updateElapsedTime()
        if timer == nil {
            startTimer()
        }
    }
    
    func showWorkoutFullScreen() {
        if activeWorkout != nil {
            isWorkoutFullScreen = true
        }
    }
    
    func minimizeWorkout() {
        isWorkoutFullScreen = false
    }
    
    func finishWorkout() {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        workout.completedAt = Date()
        
        do {
            try modelContext.save()
            activeWorkout = nil
            isWorkoutFullScreen = false
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
            isWorkoutFullScreen = false
            stopTimer()
        } catch {
            print("Error canceling workout: \(error)")
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
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
    
    nonisolated deinit {
        // Timer cleanup - must be done synchronously in deinit
        timer?.invalidate()
        timer = nil
    }
}
