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
