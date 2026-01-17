//
//  RestTimerViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import UIKit
import AudioToolbox

@MainActor
final class RestTimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 90
    @Published var isRunning: Bool = false
    @Published var isComplete: Bool = false
    
    // Expose totalSeconds for rest time tracking
    var totalDuration: Int {
        totalSeconds
    }
    
    nonisolated(unsafe) private var timer: Timer?
    private var defaultDuration: Int = 90 // Default 90 seconds
    private var targetCompletionDate: Date? // Store target completion time for wall-clock tracking
    @Published var soundEnabled: Bool = true // Toggle for sound notifications
    private var audioPlayer: AVAudioPlayer?
    
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
        
        // Store target completion time (current time + duration)
        targetCompletionDate = Date().addingTimeInterval(TimeInterval(durationToUse))
        
        startTimer()
    }
    
    func stop() {
        stopTimer()
        isRunning = false
        remainingSeconds = 0
        isComplete = false
        targetCompletionDate = nil
    }
    
    func add30Seconds() {
        guard isRunning, let targetDate = targetCompletionDate else { return }
        // Extend target completion time by 30 seconds
        targetCompletionDate = targetDate.addingTimeInterval(30)
        updateRemainingTimeInternal()
        totalSeconds = max(totalSeconds, remainingSeconds)
    }
    
    func subtract30Seconds() {
        guard isRunning, let targetDate = targetCompletionDate else { return }
        // Reduce target completion time by 30 seconds
        let newTargetDate = targetDate.addingTimeInterval(-30)
        let now = Date()
        
        if newTargetDate <= now {
            // Timer would complete immediately
            completeTimer()
        } else {
            targetCompletionDate = newTargetDate
            updateRemainingTimeInternal()
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
        // Update immediately to show correct time
        updateRemainingTimeInternal()
        
        let tickMethod = { [weak self] in
            Task { @MainActor in
                self?.tick()
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            _ = tickMethod()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard isRunning else { return }
        updateRemainingTimeInternal()
    }
    
    private func updateRemainingTimeInternal() {
        guard let targetDate = targetCompletionDate else { return }
        
        let now = Date()
        let timeRemaining = targetDate.timeIntervalSince(now)
        
        if timeRemaining <= 0 {
            // Timer has completed
            remainingSeconds = 0
            completeTimer()
        } else {
            // Round to nearest second
            remainingSeconds = max(0, Int(timeRemaining.rounded(.up)))
        }
    }
    
    // Public method to update remaining time (useful when app comes to foreground)
    func updateRemainingTime() {
        updateRemainingTimeInternal()
    }
    
    private func completeTimer() {
        stopTimer()
        isRunning = false
        isComplete = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Sound notification (if enabled)
        if soundEnabled {
            playCompletionSound()
        }
    }
    
    private func playCompletionSound() {
        // Use system sound for notification
        // System sound ID 1057 is a nice notification sound
        AudioServicesPlaySystemSound(1057)
        
        // Also try to play a custom sound if available
        // This uses the default system notification sound
        if let soundURL = Bundle.main.url(forResource: "notification", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                // Fallback to system sound if custom sound fails
                print("Could not play custom sound: \(error)")
            }
        }
    }
    
    func toggleSound() {
        soundEnabled.toggle()
    }
    
    // Public method to update remaining time (useful when app comes to foreground)
    func refreshRemainingTime() {
        updateRemainingTimeInternal()
    }
    
    nonisolated deinit {
        // Timer cleanup - must be done synchronously in deinit
        timer?.invalidate()
        timer = nil
    }
}
