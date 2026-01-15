//
//  CreateTemplateView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TemplateViewModel
    
    @State private var templateName: String = ""
    @State private var templateExercises: [TemplateExercise] = []
    @State private var showingAddExercise = false
    @State private var showingEditExercise: TemplateExercise? = nil
    
    var body: some View {
        NavigationStack {
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
                        .onDelete { indexSet in
                            deleteExercises(at: indexSet)
                        }
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
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTemplate()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseToNewTemplateSheet(
                    templateExercises: $templateExercises
                )
            }
            .sheet(item: $showingEditExercise) { exercise in
                EditTemplateExerciseSheet(
                    templateExercise: exercise,
                    isTemporary: true,
                    onSave: {
                        // Re-sort exercises after edit
                        templateExercises = templateExercises.sorted { $0.order < $1.order }
                    }
                )
            }
        }
    }
    
    private func createTemplate() {
        let name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        let template = WorkoutTemplate(name: name, createdAt: Date())
        modelContext.insert(template)
        
        // Update exercise orders, link to template, and insert into modelContext
        for (index, exercise) in templateExercises.enumerated() {
            exercise.order = index
            exercise.template = template
            modelContext.insert(exercise)
        }
        
        template.exercises = templateExercises
        
        do {
            try modelContext.save()
            viewModel.fetchAllTemplates()
            dismiss()
        } catch {
            print("Error creating template: \(error)")
        }
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        let sorted = templateExercises.sorted { $0.order < $1.order }
        
        for index in offsets {
            let exercise = sorted[index]
            templateExercises.removeAll { $0.id == exercise.id }
        }
    }
}

struct AddExerciseToNewTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var templateExercises: [TemplateExercise]
    
    @StateObject private var exerciseViewModel = ExerciseLibraryViewModel()
    @State private var selectedExercises: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            exerciseList
                .searchable(text: $exerciseViewModel.searchText, prompt: "Search exercises")
                .navigationTitle("Add Exercises")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            addSelectedExercises()
                        }
                        .disabled(selectedExercises.isEmpty)
                    }
                }
                .onAppear {
                    exerciseViewModel.setModelContext(modelContext)
                }
        }
    }
    
    private var exerciseList: some View {
        List {
            ForEach(exerciseViewModel.sortedCategories, id: \.self) { category in
                categorySection(for: category)
            }
        }
    }
    
    @ViewBuilder
    private func categorySection(for category: String) -> some View {
        if let exercises = exerciseViewModel.exercisesByCategory[category], !exercises.isEmpty {
            Section {
                ForEach(exercises) { exercise in
                    ExerciseSelectionRow(
                        exercise: exercise,
                        isSelected: selectedExercises.contains(exercise.id),
                        onToggle: {
                            toggleExercise(exercise.id)
                        }
                    )
                }
            } header: {
                Text(category)
            }
        }
    }
    
    private func toggleExercise(_ id: UUID) {
        if selectedExercises.contains(id) {
            selectedExercises.remove(id)
        } else {
            selectedExercises.insert(id)
        }
    }
    
    private func addSelectedExercises() {
        let selected = exerciseViewModel.exercises.filter { selectedExercises.contains($0.id) }
        let maxOrder = templateExercises.map { $0.order }.max() ?? -1
        
        for (index, exercise) in selected.enumerated() {
            let templateExercise = TemplateExercise(
                exercise: exercise,
                order: maxOrder + index + 1,
                defaultSets: 3,
                defaultReps: 10,
                defaultWeight: nil
            )
            templateExercises.append(templateExercise)
        }
        
        dismiss()
    }
}

#Preview {
    CreateTemplateView(viewModel: TemplateViewModel())
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
}
