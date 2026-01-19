//
//  FloatingWorkoutPill.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct FloatingWorkoutPill: View {
    @ObservedObject var workoutState: WorkoutStateManager
    let onTap: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingFinishAlert = false
    @State private var showingCancelAlert = false
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", minutes, secs)
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        if let workout = workoutState.activeWorkout {
            let workoutName = workout.name ?? "Workout"
            let isRestTimerRunning = workoutState.restTimerViewModel.isRunning
            let accessibilityValue = isRestTimerRunning
                ? "Rest \(formatRestTime(workoutState.restTimerViewModel.remainingSeconds)) remaining"
                : "Elapsed \(formatElapsedTime(workoutState.elapsedTime))"
            
            VStack {
                Button {
                    onTap()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundStyle(.tint)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workoutName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Show rest timer if active, otherwise show workout duration
                            if isRestTimerRunning {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    Text(formatRestTime(workoutState.restTimerViewModel.remainingSeconds))
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.orange)
                                }
                            } else {
                                Text(formatElapsedTime(workoutState.elapsedTime))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .contextMenu {
                    Button("Resume Workout") {
                        onTap()
                    }
                    
                    if isRestTimerRunning {
                        Button("Stop Rest Timer") {
                            workoutState.stopRestTimer()
                        }
                    } else {
                        Button("Start Rest Timer") {
                            workoutState.startRestTimer()
                        }
                    }
                    
                    Button("Finish Workout") {
                        showingFinishAlert = true
                    }
                    
                    Button("Cancel Workout", role: .destructive) {
                        showingCancelAlert = true
                    }
                }
                .accessibilityLabel(Text("Resume workout, \(workoutName)"))
                .accessibilityValue(Text(accessibilityValue))
                .accessibilityHint(Text("Opens the active workout"))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Finish", role: .destructive) {
                    workoutState.finishWorkout()
                }
            } message: {
                Text("Finish this workout now? Notes and effort rating are only available in the full workout view.")
            }
            .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                Button("Keep Workout", role: .cancel) {}
                Button("Cancel Workout", role: .destructive) {
                    workoutState.cancelWorkout()
                }
            } message: {
                Text("Canceling will discard this workout and all of its progress.")
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        FloatingWorkoutPill(
            workoutState: WorkoutStateManager(),
            onTap: {}
        )
    }
    .background(Color(.systemBackground))
}
