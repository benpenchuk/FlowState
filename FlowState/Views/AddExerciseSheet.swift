//
//  AddExerciseSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExerciseLibraryViewModel
    
    @State private var exerciseName: String = ""
    @State private var selectedCategory: ExerciseCategory = .other
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                        .autocapitalization(.words)
                } header: {
                    Text("Name")
                }
                
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        viewModel.addCustomExercise(name: trimmedName, category: selectedCategory)
        dismiss()
    }
}

#Preview {
    AddExerciseSheet(viewModel: ExerciseLibraryViewModel())
}
