//
//  ActiveWorkoutFullScreenView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutFullScreenView: View {
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @State private var showingCancelAlert = false
    @State private var showingAddExercise = false
    @State private var workoutName: String
    @State private var showingCompletedTimer: Bool = false
    
    init() {
        let vm = ActiveWorkoutViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        _workoutName = State(initialValue: "")
    }
    
    private var workout: Workout? {
        workoutState.activeWorkout
    }
    
    var body: some View {
        Group {
            if let workout = workout {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Timer
                            timerView
                            
                            // Rest Timer (shown when active)
                            if workoutState.restTimerViewModel.isRunning || showingCompletedTimer {
                                RestTimerView(
                                    viewModel: workoutState.restTimerViewModel,
                                    onSkip: {
                                        workoutState.stopRestTimer()
                                        showingCompletedTimer = false
                                    }
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .onChange(of: workoutState.restTimerViewModel.isComplete) { oldValue, newValue in
                                    if newValue {
                                        showingCompletedTimer = true
                                        // Auto-hide after 3 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            showingCompletedTimer = false
                                            workoutState.stopRestTimer()
                                        }
                                    }
                                }
                            }
                            
                            // Workout name
                            TextField("Workout Name", text: $workoutName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.plain)
                                .onChange(of: workoutName) { oldValue, newValue in
                                    workout.name = newValue.isEmpty ? nil : newValue
                                    try? modelContext.save()
                                }
                            
                            // Exercises
                            if let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty {
                                ForEach(entries) { entry in
                                    ExerciseSectionView(
                                        entry: entry,
                                        viewModel: viewModel,
                                        onSetCompleted: {
                                            // Get default rest duration from user settings (default 90s)
                                            // If timer is already running, restart it (restart on each set completion)
                                            let defaultRestDuration = 90
                                            showingCompletedTimer = false // Reset completion state
                                            workoutState.restTimerViewModel.stop() // Stop current timer
                                            workoutState.startRestTimer(duration: defaultRestDuration)
                                        }
                                    )
                                }
                            } else {
                                Text("No exercises yet")
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                            
                            // Add Exercise button
                            Button {
                                showingAddExercise = true
                            } label: {
                                Label("Add Exercise", systemImage: "plus.circle")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            // Finish Workout button
                            Button {
                                workoutState.finishWorkout()
                                dismiss()
                            } label: {
                                Text("Finish Workout")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    .navigationTitle("Active Workout")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                workoutState.minimizeWorkout()
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(role: .destructive) {
                                showingCancelAlert = true
                            } label: {
                                Text("Cancel")
                            }
                        }
                    }
                    .alert("Cancel Workout", isPresented: $showingCancelAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Discard", role: .destructive) {
                            workoutState.cancelWorkout()
                            dismiss()
                        }
                    } message: {
                        Text("Are you sure you want to discard this workout? All progress will be lost.")
                    }
                    .sheet(isPresented: $showingAddExercise) {
                        AddExerciseToWorkoutSheet(viewModel: viewModel)
                    }
                    .overlay(alignment: .center) {
                        // PR Notification
                        if let pr = viewModel.detectedPR {
                            PRNotificationView(pr: pr)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(1000)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.detectedPR?.id)
                        }
                    }
                }
            } else {
                EmptyView()
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            workoutState.showWorkoutFullScreen()
            if let workout = workout {
                viewModel.activeWorkout = workout
                workoutName = workout.name ?? ""
            }
        }
        .onChange(of: workoutState.activeWorkout?.id) { oldValue, newValue in
            if let workout = workoutState.activeWorkout {
                viewModel.activeWorkout = workout
                workoutName = workout.name ?? ""
            }
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 4) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(formatElapsedTime(workoutState.elapsedTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
