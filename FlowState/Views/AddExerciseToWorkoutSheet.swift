//
//  AddExerciseToWorkoutSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct AddExerciseToWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    
    @StateObject private var exerciseViewModel = ExerciseLibraryViewModel()
    @State private var selectedExercises: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            exerciseList
                .searchable(text: $exerciseViewModel.searchText, prompt: "Search exercises")
                .navigationTitle("Add Exercise")
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
        
        for exercise in selected {
            viewModel.addExerciseToWorkout(exercise)
        }
        
        dismiss()
    }
}

#Preview {
    AddExerciseToWorkoutSheet(viewModel: ActiveWorkoutViewModel())
        .modelContainer(for: [Exercise.self], inMemory: true)
}
