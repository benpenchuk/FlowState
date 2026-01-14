//
//  AddExerciseToTemplateSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct AddExerciseToTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var templateExercises: [TemplateExercise]
    
    @StateObject private var exerciseViewModel = ExerciseLibraryViewModel()
    @State private var selectedExercises: Set<UUID> = []
    let template: WorkoutTemplate
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(exerciseViewModel.sortedCategories, id: \.self) { category in
                    if let exercises = exerciseViewModel.exercisesByCategory[category], !exercises.isEmpty {
                        Section {
                            ForEach(exercises) { exercise in
                                ExerciseSelectionRow(
                                    exercise: exercise,
                                    isSelected: selectedExercises.contains(exercise.id),
                                    onToggle: {
                                        if selectedExercises.contains(exercise.id) {
                                            selectedExercises.remove(exercise.id)
                                        } else {
                                            selectedExercises.insert(exercise.id)
                                        }
                                    }
                                )
                            }
                        } header: {
                            Text(category.rawValue)
                        }
                    }
                }
            }
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
    
    private func addSelectedExercises() {
        print("🟢 AddExerciseToTemplateSheet.addSelectedExercises() called")
        let selected = exerciseViewModel.exercises.filter { selectedExercises.contains($0.id) }
        print("🟢 Selected \(selected.count) exercises")
        let maxOrder = templateExercises.map { $0.order }.max() ?? -1
        print("🟢 Max order: \(maxOrder)")
        
        for (index, exercise) in selected.enumerated() {
            let templateExercise = TemplateExercise(
                exercise: exercise,
                order: maxOrder + index + 1,
                defaultSets: 3,
                defaultReps: 10,
                defaultWeight: nil
            )
            templateExercise.template = template
            print("🟢 Creating TemplateExercise for: \(exercise.name), order: \(templateExercise.order)")
            templateExercises.append(templateExercise)
            modelContext.insert(templateExercise)
        }
        
        // Note: We're NOT updating template.exercises here - that will happen when save is tapped
        // But we do insert into modelContext so they're tracked
        
        do {
            try modelContext.save()
            print("🟢 modelContext.save() successful after adding exercises")
        } catch {
            print("🔴 Error saving exercises: \(error)")
        }
        
        dismiss()
    }
}

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack {
                Text(exercise.name)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let template = WorkoutTemplate(name: "Test")
    return AddExerciseToTemplateSheet(
        templateExercises: .constant([]),
        template: template
    )
    .modelContainer(for: [Exercise.self, WorkoutTemplate.self], inMemory: true)
}
