//
//  TemplateDetailView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @ObservedObject var viewModel: TemplateViewModel
    
    private let startedInEditMode: Bool
    @State private var isEditMode: Bool
    @State private var template: WorkoutTemplate
    @State private var templateName: String
    @State private var templateExercises: [TemplateExercise]
    @State private var showingAddExercise = false
    @State private var showingEditExercise: TemplateExercise? = nil
    @StateObject private var activeWorkoutViewModel = ActiveWorkoutViewModel()
    @State private var showingExistingWorkoutAlert = false
    @State private var showingDeleteConfirmation = false
    
    init(template: WorkoutTemplate, viewModel: TemplateViewModel, isEditMode: Bool = true) {
        _template = State(initialValue: template)
        _templateName = State(initialValue: template.name)
        _templateExercises = State(initialValue: template.exercises?.sorted { $0.order < $1.order } ?? [])
        self.viewModel = viewModel
        self.startedInEditMode = isEditMode
        _isEditMode = State(initialValue: isEditMode)
    }
    
    var body: some View {
        Group {
            if isEditMode {
                editModeForm
            } else {
                viewModeContent
            }
        }
        .navigationTitle(isEditMode ? "Edit Template" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if startedInEditMode {
                            dismiss()
                        } else {
                            isEditMode = false
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            isEditMode = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        
                        Menu {
                            Button {
                                viewModel.duplicateTemplate(template)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToTemplateSheet(
                templateExercises: $templateExercises,
                template: template
            )
        }
        .sheet(item: $showingEditExercise) { exercise in
            EditTemplateExerciseSheet(
                templateExercise: exercise,
                isTemporary: false,
                onSave: {
                    // Re-sort exercises after edit
                    templateExercises = templateExercises.sorted { $0.order < $1.order }
                }
            )
        }
        .alert("Active Workout", isPresented: $showingExistingWorkoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard & Start New", role: .destructive) {
                startWorkoutFromTemplate(discardExisting: true)
            }
        } message: {
            Text("You have an active workout. Discard it and start a new one?")
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteTemplate(template)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
        }
    }

    private var editModeForm: some View {
        Form {
            Section {
                TextField("Template Name", text: $templateName)
            } header: {
                Text("Name")
            }
            
            Section {
                if templateExercises.isEmpty {
                    Text("No exercises")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    let sortedExercises = templateExercises.sorted { $0.order < $1.order }
                    ForEach(sortedExercises) { templateExercise in
                        TemplateExerciseRowView(
                            templateExercise: templateExercise,
                            isEditable: true,
                            onTap: {
                                showingEditExercise = templateExercise
                            }
                        )
                    }
                    .onMove(perform: moveExercises)
                    .onDelete(perform: deleteExercises)
                }
            } header: {
                Text("Exercises")
            } footer: {
                if templateExercises.isEmpty {
                    Text("Add exercises to build your workout routine")
                }
            }
            
            Section {
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            }
        }
        .onAppear {
            templateName = template.name
            templateExercises = template.exercises?.sorted { $0.order < $1.order } ?? templateExercises
        }
    }
    
    private var viewModeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ActiveWorkoutLayout.workoutSectionSpacing) {
                templateSummaryCard
                startWorkoutButton
                templateExercisesSection
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .onAppear {
            templateName = template.name
            templateExercises = template.exercises?.sorted { $0.order < $1.order } ?? templateExercises
        }
    }
    
    private var templateSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 20
                ) {
                    InfoBadge(
                        icon: "dumbbell",
                        title: "Exercises",
                        value: "\(templateExercises.count)"
                    )
                    
                    InfoBadge(
                        icon: "calendar",
                        title: "Created",
                        value: template.createdAt.formatted(.dateTime.month().day().year())
                    )
                    
                    InfoBadge(
                        icon: "clock",
                        title: "Last used",
                        value: template.lastUsedAt?.formatted(.dateTime.month().day().year()) ?? "Never"
                    )
                }
            }
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 0.8)
        )
    }
    
    private var startWorkoutButton: some View {
        Button {
            if workoutState.hasActiveWorkout() {
                showingExistingWorkoutAlert = true
            } else {
                startWorkoutFromTemplate()
            }
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                Text("Start Workout")
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
    
    @ViewBuilder
    private var templateExercisesSection: some View {
        let sortedExercises = templateExercises.sorted { $0.order < $1.order }
        
        if sortedExercises.isEmpty {
            Text("No exercises")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        } else {
            VStack(spacing: 12) {
                ForEach(sortedExercises) { templateExercise in
                    TemplateExerciseCardView(templateExercise: templateExercise)
                }
            }
        }
    }
    
    private func startWorkoutFromTemplate(discardExisting: Bool = false) {
        activeWorkoutViewModel.setModelContext(modelContext)
        activeWorkoutViewModel.startWorkoutFromTemplate(template, discardExisting: discardExisting)
        
        if let workout = activeWorkoutViewModel.activeWorkout {
            workoutState.setActiveWorkout(workout)
            workoutState.showWorkoutFullScreen()
            
            // Keep local UI in sync with the template state (e.g., Last used badge)
            template.lastUsedAt = Date()
            try? modelContext.save()
        }
    }
    
    private func saveTemplate() {
        print("🔵 TemplateDetailView.saveTemplate() called")
        print("🔵 Template name: \(templateName)")
        print("🔵 Number of exercises in state: \(templateExercises.count)")
        print("🔵 Current template.exercises count: \(template.exercises?.count ?? 0)")
        
        template.name = templateName
        
        // Find exercises that were removed (in template.exercises but not in templateExercises)
        let currentExerciseIds = Set(templateExercises.map { $0.id })
        if let oldExercises = template.exercises {
            let exercisesToDelete = oldExercises.filter { !currentExerciseIds.contains($0.id) }
            print("🔵 Exercises to delete: \(exercisesToDelete.count)")
            for exerciseToDelete in exercisesToDelete {
                print("🔵 Deleting: \(exerciseToDelete.exercise?.name ?? "unknown")")
                modelContext.delete(exerciseToDelete)
            }
        }
        
        // Update exercise orders and ensure they're linked to template
        for (index, exercise) in templateExercises.enumerated() {
            exercise.order = index
            exercise.template = template
            print("🔵 Exercise \(index): \(exercise.exercise?.name ?? "unknown"), order: \(exercise.order)")
        }
        
        // Update template's exercises array
        template.exercises = templateExercises
        
        print("🔵 Template exercises count after assignment: \(template.exercises?.count ?? 0)")
        if let exercises = template.exercises {
            print("🔵 Template exercises: \(exercises.map { $0.exercise?.name ?? "unknown" })")
        }
        
        do {
            try modelContext.save()
            print("🔵 modelContext.save() successful")
            viewModel.fetchAllTemplates()
        } catch {
            print("🔴 Error saving template: \(error)")
        }
        
        dismiss()
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        let sorted = templateExercises.sorted { $0.order < $1.order }
        var reordered = sorted
        
        reordered.move(fromOffsets: source, toOffset: destination)
        
        // Update orders
        for (index, exercise) in reordered.enumerated() {
            exercise.order = index
        }
        
        templateExercises = reordered
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        let sorted = templateExercises.sorted { $0.order < $1.order }
        
        for index in offsets {
            let exercise = sorted[index]
            templateExercises.removeAll { $0.id == exercise.id }
            modelContext.delete(exercise)
        }
    }
}

private struct TemplateExerciseCardView: View {
    let templateExercise: TemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text((templateExercise.exercise?.category ?? "Exercise").uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            
            Divider()
                .opacity(0.5)
            
            HStack(spacing: 14) {
                Label("\(templateExercise.defaultSets)", systemImage: "square.stack.3d.up")
                    .labelStyle(.titleAndIcon)
                
                Text("×")
                    .foregroundStyle(.secondary)
                
                Text("\(templateExercise.defaultReps)")
                    .font(.body.monospacedDigit())
                    .fontWeight(.semibold)
                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let weight = templateExercise.defaultWeight {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(String(format: weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", weight))
                        .font(.body.monospacedDigit())
                        .fontWeight(.semibold)
                    Text("lbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .font(.subheadline)
            .padding(.horizontal, 4)
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 0.8)
        )
    }
}

struct TemplateExerciseRowView: View {
    let templateExercise: TemplateExercise
    let isEditable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Group {
            if isEditable {
                Button {
                    onTap()
                } label: {
                    rowContent(showChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                rowContent(showChevron: false)
            }
        }
    }
    
    private func rowContent(showChevron: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                    .foregroundStyle(.primary)
                    .font(.body)
                
                Text("\(templateExercise.defaultSets) sets × \(templateExercise.defaultReps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let weight = templateExercise.defaultWeight {
                    Text("\(weight, specifier: "%.1f") lbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(
            template: WorkoutTemplate(name: "Push Day"),
            viewModel: TemplateViewModel()
        )
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
        .environmentObject(WorkoutStateManager())
    }
}
