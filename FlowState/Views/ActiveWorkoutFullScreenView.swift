//
//  ActiveWorkoutFullScreenView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

// PreferenceKey for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // When multiple preferences are merged, prefer non-default values
        // If nextValue() returns non-zero, use it. Otherwise keep current value.
        let newValue = nextValue()
        // Use newValue only if it's not the default (0), otherwise keep existing value
        // This prevents default values from overwriting actual scroll positions
        if abs(newValue) > 0.001 {
            value = newValue
        }
        // If both are zero or defaults, that's fine - we keep value
    }
}

struct ActiveWorkoutFullScreenView: View {
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingCancelAlert = false
    @State private var showingAddExercise = false
    @State private var showingCompletedTimer: Bool = false
    @State private var showingCompletionSheet = false
    @State private var scrollOffset: CGFloat = 0
    
    init() {
        let vm = ActiveWorkoutViewModel()
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    private var workout: Workout? {
        workoutState.activeWorkout
    }
    
    var body: some View {
        ZStack {
            // Solid background to prevent anything showing through
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Group {
                if let workout = workout {
                    workoutContentView(workout: workout)
                } else {
                    EmptyView()
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            profileViewModel.setModelContext(modelContext)
            workoutState.showWorkoutFullScreen()
            if let workout = workout {
                viewModel.activeWorkout = workout
            }
        }
        .onChange(of: workoutState.activeWorkout?.id) { oldValue, newValue in
            if let workout = workoutState.activeWorkout {
                viewModel.activeWorkout = workout
            }
        }
    }
    
    @ViewBuilder
    private func workoutContentView(workout: Workout) -> some View {
        NavigationStack {
            ZStack {
                // Solid background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Dynamic header (full or compact based on scroll)
                    Group {
                        if scrollOffset < 50 {
                            fullHeaderView(workout: workout)
                        } else {
                            compactPillsView(workout: workout)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
                    
                    // Scrollable content area
                    ScrollView {
                        VStack(spacing: 0) {
                            workoutContentBody(workout: workout)
                        }
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        })
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newValue in
                        // At top: minY ≈ 0 or positive  
                        // Scrolled down: minY becomes negative
                        // scrollOffset increases as user scrolls down
                        scrollOffset = max(0, -newValue)
                    }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    hideKeyboard()
                                }
                            )
                    )
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .tint(.orange)
                }
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
            .sheet(isPresented: $showingCompletionSheet) {
                if let activeWorkout = workoutState.activeWorkout {
                    WorkoutCompletionView(
                        workout: activeWorkout,
                        duration: workoutState.elapsedTime,
                        exerciseCount: activeWorkout.entries?.count ?? 0,
                        completedSetCount: countCompletedSets(in: activeWorkout),
                        prCount: viewModel.detectedPR != nil ? 1 : 0, // Simple PR count for now
                        onSave: { effortRating, notes in
                            viewModel.finishWorkout(effortRating: effortRating, notes: notes)
                            workoutState.finishWorkout()
                            dismiss()
                        }
                    )
                }
            }
            .overlay(alignment: .center) {
                prNotificationOverlay
            }
        }
    }
    
    @ViewBuilder
    private func fullHeaderView(workout: Workout) -> some View {
        VStack(spacing: 12) {
            // Timer
            timerView
            
            // Rest Timer (shown when active)
            if workoutState.restTimerViewModel.isRunning || showingCompletedTimer {
                restTimerView
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
    }
    
    @ViewBuilder
    private func compactPillsView(workout: Workout) -> some View {
        HStack(spacing: 8) {
            // Duration pill
            compactDurationPill
            
            // Rest timer pill (if active)
            if workoutState.restTimerViewModel.isRunning || showingCompletedTimer {
                compactRestTimerPill
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
    }
    
    private var compactDurationPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.orange)
            Text("Duration: \(formatElapsedTime(workoutState.elapsedTime))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var compactRestTimerPill: some View {
        HStack(spacing: 6) {
            // Tiny circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 2)
                    .frame(width: 16, height: 16)
                
                let progress = workoutState.restTimerViewModel.totalSeconds > 0 ?
                    Double(workoutState.restTimerViewModel.remainingSeconds) / Double(workoutState.restTimerViewModel.totalSeconds) : 0
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-90))
            }
            
            Text("Rest: \(formatRestTime(workoutState.restTimerViewModel.remainingSeconds))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    
    @ViewBuilder
    private func workoutContentBody(workout: Workout) -> some View {
        VStack(spacing: ActiveWorkoutLayout.workoutSectionSpacing) {
            // Workout name
            workoutNameField(workout: workout)
            
            // Exercises
            exercisesSection(workout: workout)
            
            // Add Exercise button
            addExerciseButton
            
            // Finish Workout button
            finishWorkoutButton
        }
        .padding(ActiveWorkoutLayout.contentPadding)
        .frame(maxWidth: .infinity)
    }
    
    private var restTimerView: some View {
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
    
    private func workoutNameField(workout: Workout) -> some View {
        Text(workout.name ?? "Workout")
            .font(.title2)
            .fontWeight(.bold)
    }
    
    @ViewBuilder
    private func exercisesSection(workout: Workout) -> some View {
        if let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty {
            ForEach(entries) { entry in
                ExerciseSectionView(
                    entry: entry,
                    viewModel: viewModel,
                    onSetCompleted: {
                        // Get default rest duration from user settings
                        let defaultRestDuration = profileViewModel.profile?.defaultRestTime ?? 90
                        showingCompletedTimer = false // Reset completion state
                        workoutState.restTimerViewModel.stop() // Stop current timer
                        workoutState.startRestTimer(duration: defaultRestDuration)
                    },
                    preferredUnits: profileViewModel.profile?.units ?? .lbs
                )
            }
        } else {
            Text("No exercises yet")
                .foregroundStyle(.secondary)
                .padding()
        }
    }
    
    private var addExerciseButton: some View {
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
    }
    
    private var finishWorkoutButton: some View {
        Button {
            showingCompletionSheet = true
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
    
    private func countCompletedSets(in workout: Workout) -> Int {
        guard let entries = workout.entries else { return 0 }
        
        var totalCompleted = 0
        for entry in entries {
            let sets = entry.getSets()
            totalCompleted += sets.filter { $0.isCompleted }.count
        }
        return totalCompleted
    }
    
    @ViewBuilder
    private var prNotificationOverlay: some View {
        if let pr = viewModel.detectedPR {
            PRNotificationView(pr: pr)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.detectedPR?.id)
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

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
