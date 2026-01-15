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
            Button {
                onTap()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name ?? "Workout")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // Show rest timer if active, otherwise show workout duration
                        if workoutState.restTimerViewModel.isRunning {
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
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
