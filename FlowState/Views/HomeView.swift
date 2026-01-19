//
//  HomeView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @StateObject private var templateViewModel = TemplateViewModel()
    @StateObject private var workoutViewModel = ActiveWorkoutViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var statsViewModel = HomeStatsViewModel()
    @State private var showingTemplates = false
    @State private var selectedTemplate: WorkoutTemplate? = nil
    @State private var showingExistingWorkoutAlert = false
    @State private var templateToStart: WorkoutTemplate? = nil
    @State private var startingEmpty = false
    @State private var userProfile: UserProfile?
    @State private var templateToEdit: WorkoutTemplate? = nil
    @State private var templateToDelete: WorkoutTemplate? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Logo Section
                logoSection
                
                // Greeting Section
                greetingSection
                
                // Weekly Stats Card
                weeklyStatsCard

                // Quick Start Section
                quickStartSection

                // Templates Section
                templatesSection

                // Recent PRs Section
                recentPRsSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .task {
            templateViewModel.setModelContext(modelContext)
            workoutViewModel.setModelContext(modelContext)
            progressViewModel.setModelContext(modelContext)
            statsViewModel.setModelContext(modelContext)
            loadUserProfile()
        }
        .onAppear {
            // Refresh stats whenever the view appears (e.g., when switching tabs)
            statsViewModel.refreshStats()
        }
        .onChange(of: workoutState.activeWorkout) { oldValue, newValue in
            // Refresh stats when active workout changes (e.g., when a workout is completed)
            if oldValue != nil && newValue == nil {
                // Workout was just completed, refresh stats
                statsViewModel.refreshStats()
            }
        }
        .alert("Start Workout", isPresented: Binding(
            get: { selectedTemplate != nil },
            set: { if !$0 { selectedTemplate = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                selectedTemplate = nil
            }
            Button("Start") {
                if let template = selectedTemplate {
                    if workoutState.hasActiveWorkout() {
                        templateToStart = template
                        showingExistingWorkoutAlert = true
                    } else {
                        startWorkoutFromTemplate(template)
                    }
                    selectedTemplate = nil
                }
            }
        } message: {
            if let template = selectedTemplate {
                Text("Start workout from \"\(template.name)\"?")
            }
        }
        .alert("Active Workout", isPresented: $showingExistingWorkoutAlert) {
            Button("Cancel", role: .cancel) {
                templateToStart = nil
                startingEmpty = false
            }
            Button("Discard & Start New", role: .destructive) {
                if let template = templateToStart {
                    startWorkoutFromTemplate(template, discardExisting: true)
                    templateToStart = nil
                } else if startingEmpty {
                    startEmptyWorkout(discardExisting: true)
                    startingEmpty = false
                }
            }
        } message: {
            Text("You have an active workout. Discard it and start a new one?")
        }
        .sheet(item: $templateToEdit) { template in
            NavigationStack {
                TemplateDetailView(template: template, viewModel: templateViewModel)
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    templateViewModel.deleteTemplate(template)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
            }
        }
    }
    
    private var logoSection: some View {
        HStack(spacing: 12) {
            Image(colorScheme == .dark ? "FlowStateLogoDark" : "FlowStateLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 45)

            Text("FlowState")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.bottom, 2)
    }
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Keep up the momentum!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var weeklyStatsCard: some View {
        VStack(spacing: 16) {
            // Period Selector
            Picker("Period", selection: $statsViewModel.selectedPeriod) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            // Stats Content
            if statsViewModel.isLoading {
                SkeletonStatsCard()
            } else {
                HStack(spacing: 0) {
                    // Workouts Count
                    Button {
                        // Action for workouts - could navigate to history
                    } label: {
                        StatItemView(
                            value: "\(statsViewModel.workoutsCount)",
                            label: "Workouts",
                            previousValue: statsViewModel.previousWorkoutsCount,
                            currentValue: statsViewModel.workoutsCount
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    
                    Divider()
                        .frame(height: 50)
                    
                    // Total Time
                    Button {
                        // Action for time
                    } label: {
                        StatItemView(
                            value: formatTime(statsViewModel.totalTime),
                            label: "Total Time",
                            previousValue: Int(statsViewModel.previousTotalTime / 60),
                            currentValue: Int(statsViewModel.totalTime / 60),
                            isTime: true
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    
                    Divider()
                        .frame(height: 50)
                    
                    // Current Streak
                    Button {
                        // Action for streak - could show mini-calendar
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(statsViewModel.currentStreak)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                                .contentTransition(.numericText())
                            
                            Text("Day Streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // Mini-calendar dots (last 7 days)
                            HStack(spacing: 3) {
                                ForEach(0..<statsViewModel.last7DaysActivity.count, id: \.self) { index in
                                    Circle()
                                        .fill(statsViewModel.last7DaysActivity[index] ? Color.accentColor : Color(.systemGray5))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        
        if hour < 12 {
            timeOfDay = "Good morning"
        } else if hour < 18 {
            timeOfDay = "Good afternoon"
        } else {
            timeOfDay = "Good evening"
        }
        
        let name = userProfile?.name ?? "Athlete"
        return "\(timeOfDay), \(name)"
    }
    
    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            userProfile = profiles.first
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval == 0 {
            return "—"
        }
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Start From Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingTemplates = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }
            
            if templateViewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonTemplateCard()
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else if templateViewModel.templates.isEmpty {
                VStack(spacing: 8) {
                    Text("No templates yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showingTemplates = true
                    } label: {
                        Text("Create Your First Template")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(templateViewModel.templates.prefix(5))) { template in
                            TemplateCardView(
                                template: template,
                                onTap: {
                                    selectedTemplate = template
                                },
                                onEdit: {
                                    templateToEdit = template
                                },
                                onDuplicate: {
                                    templateViewModel.duplicateTemplate(template)
                                },
                                onDelete: {
                                    templateToDelete = template
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .sheet(isPresented: $showingTemplates) {
            NavigationStack {
                TemplateListView()
            }
        }
    }
    
    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Recent PRs")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if progressViewModel.isLoading {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonPRCard()
                    }
                }
            } else if progressViewModel.recentPRs.isEmpty {
                VStack(spacing: 8) {
                    Text("No recent PRs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Complete workouts to track your progress!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(progressViewModel.recentPRs.prefix(5)) { pr in
                        PRCardView(pr: pr)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private var quickStartSection: some View {
        Button {
            if workoutState.hasActiveWorkout() {
                showingExistingWorkoutAlert = true
                startingEmpty = true
            } else {
                startEmptyWorkout()
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Start Empty Workout")
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(16)
        }
    }
    
    private func startEmptyWorkout(discardExisting: Bool = false) {
        workoutViewModel.setModelContext(modelContext)
        workoutViewModel.startEmptyWorkout(discardExisting: discardExisting)
        
        if let workout = workoutViewModel.activeWorkout {
            workoutState.setActiveWorkout(workout)
            workoutState.showWorkoutFullScreen()
        }
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate, discardExisting: Bool = false) {
        workoutViewModel.setModelContext(modelContext)
        workoutViewModel.startWorkoutFromTemplate(template, discardExisting: discardExisting)
        
        if let workout = workoutViewModel.activeWorkout {
            workoutState.setActiveWorkout(workout)
            workoutState.showWorkoutFullScreen()
            
            // Update template's lastUsedAt
            template.lastUsedAt = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Helper Functions
private func formatShortRelativeDate(_ date: Date) -> String {
    let diff = Int(Date().timeIntervalSince(date))
    if diff < 60 { return "now" }
    if diff < 3600 { return "\(diff / 60)m ago" }
    if diff < 86400 { return "\(diff / 3600)h ago" }
    if diff < 604800 { return "\(diff / 86400)d ago" }
    return date.formatted(.dateTime.month().day())
}

struct TemplateCardView: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                        .font(.subheadline)
                }
                .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 6) {
                    let exercises = template.exercises?.sorted(by: { $0.order < $1.order }) ?? []
                    let displayCount = min(3, exercises.count)
                    
                    ForEach(exercises.prefix(displayCount), id: \.id) { exercise in
                        HStack(spacing: 4) {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(exercise.exercise?.name ?? "Unknown")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(exercise.defaultSets)×\(exercise.defaultReps)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if exercises.count > displayCount {
                        Text("+\(exercises.count - displayCount) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                            .padding(.leading, 8)
                    }
                }
                
                Spacer(minLength: 8)
                
                HStack {
                    if let lastUsed = template.lastUsedAt {
                        let shortDate = formatShortRelativeDate(lastUsed)
                        Text("Last used \(shortDate)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never used")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Label("\(template.exercises?.count ?? 0)", systemImage: "dumbbell")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(width: 220, height: 150, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Template", systemImage: "pencil")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct PRCardView: View {
    let pr: PersonalRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", pr.weight)) lbs")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("× \(pr.reps)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(pr.achievedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let daysAgo = daysSince(pr.achievedAt) {
                    Text("\(daysAgo)d ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func daysSince(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    let previousValue: Int
    let currentValue: Int
    var isTime: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Comparison indicator
            let diff = currentValue - previousValue
            if diff != 0 {
                HStack(spacing: 2) {
                    Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(abs(diff) == diff ? "+\(abs(diff))" : "\(diff)")
                        .font(.caption2)
                }
                .foregroundStyle(diff > 0 ? .green : .red)
            } else if currentValue > 0 || previousValue > 0 {
                // If there was activity but no change, show a neutral indicator
                Text("No change")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
    }
}
