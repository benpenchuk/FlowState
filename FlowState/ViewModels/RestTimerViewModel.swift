//
//  RestTimerViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RestTimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 90
    @Published var isRunning: Bool = false
    @Published var isComplete: Bool = false
    
    nonisolated(unsafe) private var timer: Timer?
    private var defaultDuration: Int = 90 // Default 90 seconds
    
    init(defaultDuration: Int = 90) {
        self.defaultDuration = defaultDuration
        self.totalSeconds = defaultDuration
    }
    
    func start(duration: Int? = nil) {
        let durationToUse = duration ?? defaultDuration
        totalSeconds = durationToUse
        remainingSeconds = durationToUse
        isRunning = true
        isComplete = false
        
        startTimer()
    }
    
    func stop() {
        stopTimer()
        isRunning = false
        remainingSeconds = 0
        isComplete = false
    }
    
    func add30Seconds() {
        guard isRunning else { return }
        remainingSeconds = min(remainingSeconds + 30, 999) // Cap at 999 seconds
        totalSeconds = max(totalSeconds, remainingSeconds)
    }
    
    func subtract30Seconds() {
        guard isRunning else { return }
        remainingSeconds = max(remainingSeconds - 30, 0)
        if remainingSeconds == 0 {
            completeTimer()
        }
    }
    
    func setDefaultDuration(_ seconds: Int) {
        defaultDuration = seconds
        if !isRunning {
            totalSeconds = seconds
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard isRunning else { return }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        stopTimer()
        isRunning = false
        isComplete = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    nonisolated deinit {
        // Timer cleanup - must be done synchronously in deinit
        timer?.invalidate()
        timer = nil
    }
}
