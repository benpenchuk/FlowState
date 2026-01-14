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
    @ObservedObject var viewModel: TemplateViewModel
    
    @State private var template: WorkoutTemplate
    @State private var templateName: String
    @State private var templateExercises: [TemplateExercise]
    @State private var showingAddExercise = false
    @State private var showingEditExercise: TemplateExercise? = nil
    
    init(template: WorkoutTemplate, viewModel: TemplateViewModel) {
        _template = State(initialValue: template)
        _templateName = State(initialValue: template.name)
        _templateExercises = State(initialValue: template.exercises?.sorted { $0.order < $1.order } ?? [])
        self.viewModel = viewModel
    }
    
    var body: some View {
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
                    ForEach(templateExercises.sorted { $0.order < $1.order }) { templateExercise in
                        TemplateExerciseRowView(
                            templateExercise: templateExercise,
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
        .navigationTitle("Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
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

struct TemplateExerciseRowView: View {
    let templateExercise: TemplateExercise
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(
            template: WorkoutTemplate(name: "Push Day"),
            viewModel: TemplateViewModel()
        )
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
    }
}
