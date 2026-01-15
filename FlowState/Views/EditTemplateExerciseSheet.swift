//
//  EditTemplateExerciseSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct EditTemplateExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let templateExercise: TemplateExercise
    let isTemporary: Bool
    let onSave: () -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    @State private var weight: Double?
    @State private var hasWeight: Bool
    
    init(templateExercise: TemplateExercise, isTemporary: Bool = false, onSave: @escaping () -> Void) {
        self.templateExercise = templateExercise
        self.isTemporary = isTemporary
        self.onSave = onSave
        _sets = State(initialValue: templateExercise.defaultSets)
        _reps = State(initialValue: templateExercise.defaultReps)
        _weight = State(initialValue: templateExercise.defaultWeight)
        _hasWeight = State(initialValue: templateExercise.defaultWeight != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Exercise")
                }
                
                Section {
                    Stepper(value: $sets, in: 1...10) {
                        HStack {
                            Text("Sets")
                            Spacer()
                            Text("\(sets)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Stepper(value: $reps, in: 1...50) {
                        HStack {
                            Text("Reps")
                            Spacer()
                            Text("\(reps)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Defaults")
                }
                
                Section {
                    Toggle("Default Weight", isOn: $hasWeight)
                    
                    if hasWeight {
                        HStack {
                            TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                            Text("lbs")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Weight (Optional)")
                }
            }
            .navigationTitle("Edit Exercise")
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
                }
            }
        }
    }
    
    private func saveExercise() {
        templateExercise.defaultSets = sets
        templateExercise.defaultReps = reps
        templateExercise.defaultWeight = hasWeight ? weight : nil
        
        // Only save to modelContext if the exercise is already persisted
        // Temporary exercises (not yet in database) don't need saving
        if !isTemporary {
            do {
                try modelContext.save()
            } catch {
                print("Error saving exercise: \(error)")
            }
        }
        
        onSave()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, TemplateExercise.self, configurations: config)
    let exercise = Exercise(name: "Bench Press", exerciseType: .strength, category: "Chest", equipment: [.barbell, .bench])
    let templateExercise = TemplateExercise(exercise: exercise, order: 0, defaultSets: 3, defaultReps: 10)
    
    return EditTemplateExerciseSheet(templateExercise: templateExercise, isTemporary: false) {}
        .modelContainer(container)
}
