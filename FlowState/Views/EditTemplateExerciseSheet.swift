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
    @State private var showingCustomNumPad = false
    @State private var numPadValue: String = ""
    @State private var editingField: EditingField?
    
    enum EditingField {
        case sets
        case reps
        case weight
    }
    
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
                    Button {
                        editingField = .sets
                        numPadValue = String(sets)
                        showingCustomNumPad = true
                    } label: {
                        HStack {
                            Text("Sets")
                            Spacer()
                            Text("\(sets)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        editingField = .reps
                        numPadValue = String(reps)
                        showingCustomNumPad = true
                    } label: {
                        HStack {
                            Text("Reps")
                            Spacer()
                            Text("\(reps)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Toggle("Default Weight", isOn: $hasWeight)
                    
                    if hasWeight {
                        Button {
                            editingField = .weight
                            numPadValue = weight.map { String(format: "%.1f", $0) } ?? ""
                            showingCustomNumPad = true
                        } label: {
                            HStack {
                                Text(weight.map { String(format: "%.1f", $0) } ?? "0.0")
                                    .foregroundStyle(.primary)
                                Text("lbs")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Defaults")
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
            .sheet(isPresented: $showingCustomNumPad) {
                if let field = editingField {
                    CustomNumPadView(
                        value: $numPadValue,
                        showDecimal: field == .weight,
                        fieldLabel: field == .sets ? "Sets" : (field == .reps ? "Reps" : "Weight"),
                        preferredUnits: field == .weight ? .lbs : nil,
                        onDone: {
                            showingCustomNumPad = false
                            
                            switch field {
                            case .sets:
                                if let newSets = Int(numPadValue), newSets > 0 {
                                    sets = newSets
                                }
                            case .reps:
                                if let newReps = Int(numPadValue), newReps > 0 {
                                    reps = newReps
                                }
                            case .weight:
                                if let newWeight = Double(numPadValue) {
                                    weight = newWeight
                                } else if numPadValue.isEmpty {
                                    weight = nil
                                }
                            }
                            
                            editingField = nil
                        }
                    )
                    .presentationDetents([.height(500)])
                    .presentationDragIndicator(.visible)
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
