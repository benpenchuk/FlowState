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
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @StateObject private var templateViewModel = TemplateViewModel()
    @StateObject private var workoutViewModel = ActiveWorkoutViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @State private var showingTemplates = false
    @State private var selectedTemplate: WorkoutTemplate? = nil
    @State private var showingExistingWorkoutAlert = false
    @State private var templateToStart: WorkoutTemplate? = nil
    @State private var startingEmpty = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Templates Section
                templatesSection
                
                // Recent PRs Section
                recentPRsSection
                
                // Quick Start Section
                quickStartSection
            }
            .padding()
        }
        .navigationTitle("Home")
        .onAppear {
            templateViewModel.setModelContext(modelContext)
            workoutViewModel.setModelContext(modelContext)
            progressViewModel.setModelContext(modelContext)
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
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Workout Templates")
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
            
            if templateViewModel.templates.isEmpty {
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
                            TemplateCardView(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationStack {
                TemplateListView()
            }
        }
    }
    
    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Recent PRs")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if progressViewModel.recentPRs.isEmpty {
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
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.title2)
                .fontWeight(.semibold)
            
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
                .cornerRadius(12)
            }
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

struct TemplateCardView: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label("\(template.exercises?.count ?? 0)", systemImage: "dumbbell")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .frame(width: 160, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
    }
}
