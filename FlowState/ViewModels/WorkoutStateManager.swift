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
    @Published var restTimerViewModel: RestTimerViewModel
    
    private var modelContext: ModelContext?
    nonisolated(unsafe) private var timer: Timer?
    private var totalRestTimeAccumulated: TimeInterval = 0 // Track total rest time during workout
    private var restTimerStartTime: Date? // Track when current rest timer started
    
    init() {
        self.restTimerViewModel = RestTimerViewModel(defaultDuration: 90)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadActiveWorkout()
        startTimer()
        observeRestTimerCompletion()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func observeRestTimerCompletion() {
        // Observe when rest timer completes naturally
        restTimerViewModel.$isComplete
            .dropFirst()
            .sink { [weak self] isComplete in
                Task { @MainActor in
                    if isComplete {
                        self?.handleRestTimerCompleted()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleRestTimerCompleted() {
        // Accumulate rest time when timer completes naturally
        if restTimerStartTime != nil {
            // When timer completes, all time was used
            totalRestTimeAccumulated += TimeInterval(restTimerViewModel.totalSeconds)
            restTimerStartTime = nil
        }
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
            if activeWorkout != nil {
                totalRestTimeAccumulated = 0 // Reset when loading existing workout
            }
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
        totalRestTimeAccumulated = 0 // Reset rest time tracking for new workout
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
        
        // Add any remaining rest time if timer is running
        if restTimerViewModel.isRunning, restTimerStartTime != nil {
            let restTimeUsed = restTimerViewModel.totalSeconds - restTimerViewModel.remainingSeconds
            totalRestTimeAccumulated += TimeInterval(restTimeUsed)
            restTimerStartTime = nil
        }
        
        workout.completedAt = Date()
        workout.totalRestTime = totalRestTimeAccumulated > 0 ? totalRestTimeAccumulated : nil
        restTimerViewModel.stop()
        
        do {
            try modelContext.save()
            activeWorkout = nil
            isWorkoutFullScreen = false
            totalRestTimeAccumulated = 0 // Reset for next workout
            stopTimer()
        } catch {
            print("Error finishing workout: \(error)")
        }
    }
    
    func cancelWorkout() {
        guard let modelContext = modelContext,
              let workout = activeWorkout else { return }
        
        modelContext.delete(workout)
        restTimerViewModel.stop()
        
        do {
            try modelContext.save()
            activeWorkout = nil
            isWorkoutFullScreen = false
            stopTimer()
        } catch {
            print("Error canceling workout: \(error)")
        }
    }
    
    func startRestTimer(duration: Int? = nil) {
        // If timer was already running, accumulate the time used
        if restTimerViewModel.isRunning, restTimerStartTime != nil {
            let restTimeUsed = restTimerViewModel.totalSeconds - restTimerViewModel.remainingSeconds
            totalRestTimeAccumulated += TimeInterval(restTimeUsed)
        }
        
        restTimerViewModel.start(duration: duration)
        restTimerStartTime = Date()
    }
    
    func stopRestTimer() {
        // Accumulate rest time when timer is stopped (skipped)
        // Note: Natural completion is handled by observeRestTimerCompletion()
        if restTimerViewModel.isRunning, restTimerStartTime != nil {
            let restTimeUsed = restTimerViewModel.totalSeconds - restTimerViewModel.remainingSeconds
            totalRestTimeAccumulated += TimeInterval(restTimeUsed)
            restTimerStartTime = nil
        }
        
        restTimerViewModel.stop()
    }
    
    private func startTimer() {
        stopTimer()
        let weakSelf = self
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor [weak weakSelf] in
                weakSelf?.updateElapsedTime()
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
