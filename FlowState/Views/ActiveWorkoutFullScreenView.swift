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
    @State private var restTimerPulse = false
    
    init() {
        let vm = ActiveWorkoutViewModel()
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    private var workout: Workout? {
        workoutState.activeWorkout
    }
    
    var body: some View {
        ZStack {
            // Background color for the whole view
            Color(.systemGroupedBackground)
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
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Dynamic header (full or compact based on scroll)
                    Group {
                        if scrollOffset < ActiveWorkoutLayout.headerTransitionThreshold {
                            fullHeaderView(workout: workout)
                        } else {
                            compactPillsView(workout: workout)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
                    
                    Divider()
                    
                    // Scrollable content area
                    ScrollViewReader { proxy in
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
                        .onChange(of: viewModel.scrollToSetId) { oldValue, newValue in
                            if let id = newValue {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                                // Reset after scrolling
                                viewModel.scrollToSetId = nil
                            }
                        }
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
                Button("Keep Workout", role: .cancel) {}
                Button("Discard Workout", role: .destructive) {
                    workoutState.cancelWorkout()
                    dismiss()
                }
            } message: {
                Text(cancelAlertMessage)
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
    
    private var exerciseProgress: (completed: Int, total: Int) {
        guard let workout = workout, let entries = workout.entries else { return (0, 0) }
        let completed = entries.filter { entry in
            let sets = entry.getSets()
            return !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
        }.count
        return (completed, entries.count)
    }
    
    @ViewBuilder
    private func fullHeaderView(workout: Workout) -> some View {
        VStack(spacing: 12) {
            // Progress Section
            let progress = exerciseProgress
            if progress.total > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("Workout Progress")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(progress.completed)/\(progress.total) Exercises")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * CGFloat(Double(progress.completed) / Double(progress.total)))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 4)
            }

            // Timer
            timerView
            
            // Rest Timer (shown when active)
            if workoutState.restTimerViewModel.isRunning || showingCompletedTimer {
                restTimerView
            }
        }
        .padding(.horizontal, ActiveWorkoutLayout.contentPadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
    }
    
    @ViewBuilder
    private func compactPillsView(workout: Workout) -> some View {
        HStack(spacing: 8) {
            // Progress pill
            let progress = exerciseProgress
            if progress.total > 0 {
                compactProgressPill(progress: progress)
            }
            
            // Duration pill
            compactDurationPill
            
            // Rest timer pill (if active)
            if workoutState.restTimerViewModel.isRunning || showingCompletedTimer {
                compactRestTimerPill
            }
        }
        .padding(.horizontal, ActiveWorkoutLayout.contentPadding)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
    }
    
    private func compactProgressPill(progress: (completed: Int, total: Int)) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.orange)
            Text("\(progress.completed)/\(progress.total)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var compactDurationPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.orange)
            Text("\(formatElapsedTime(workoutState.elapsedTime))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var compactRestTimerPill: some View {
        HStack(spacing: 6) {
            // Tiny circular progress indicator
            ZStack {
                Circle()
                    .stroke(restTimerPulse ? Color.orange.opacity(0.3) : Color(.systemGray5), lineWidth: 2)
                    .frame(width: 16, height: 16)
                
                let progress = workoutState.restTimerViewModel.totalSeconds > 0 ?
                    Double(workoutState.restTimerViewModel.remainingSeconds) / Double(workoutState.restTimerViewModel.totalSeconds) : 0
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(restTimerPulse ? Color.white : Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-90))
            }
            
            Text("\(formatRestTime(workoutState.restTimerViewModel.remainingSeconds))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(restTimerPulse ? .white : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(restTimerPulse ? Color.orange : Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .scaleEffect(restTimerPulse ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: restTimerPulse)
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
        .scaleEffect(restTimerPulse ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: restTimerPulse)
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
        HStack {
            Text(workout.name ?? "Workout")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func exercisesSection(workout: Workout) -> some View {
        if let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty {
            let firstIncompleteId = entries.first(where: { entry in
                let sets = entry.getSets()
                return sets.isEmpty || !sets.allSatisfy { $0.isCompleted }
            })?.id
            
            ForEach(entries) { entry in
                ExerciseSectionView(
                    entry: entry,
                    viewModel: viewModel,
                    isActive: entry.id == firstIncompleteId,
                    onSetCompleted: {
                        // Get default rest duration from user settings
                        let defaultRestDuration = profileViewModel.profile?.defaultRestTime ?? 90
                        showingCompletedTimer = false // Reset completion state
                        workoutState.restTimerViewModel.stop() // Stop current timer
                        workoutState.startRestTimer(duration: defaultRestDuration)
                        
                        // Pulse animation for the rest timer indicator
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            restTimerPulse = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                restTimerPulse = false
                            }
                        }
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
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
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
    
    private var cancelAlertMessage: String {
        guard let workout = workoutState.activeWorkout else { return "Are you sure you want to discard this workout?" }
        let completed = countCompletedSets(in: workout)
        if completed > 0 {
            return "You've completed \(completed) set\(completed == 1 ? "" : "s"). Are you sure you want to discard this workout? This cannot be undone."
        } else {
            return "Are you sure you want to discard this workout? All progress will be lost."
        }
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
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(formatElapsedTime(workoutState.elapsedTime))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
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
