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
    @State private var setLabels: [SetLabel]
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
        
        // Initialize labels array
        let existingLabels = templateExercise.getDefaultLabels()
        var initialLabels = existingLabels
        // Pad with .none if we have more sets than labels
        while initialLabels.count < templateExercise.defaultSets {
            initialLabels.append(.none)
        }
        // Trim if we have fewer sets
        if initialLabels.count > templateExercise.defaultSets {
            initialLabels = Array(initialLabels.prefix(templateExercise.defaultSets))
        }
        _setLabels = State(initialValue: initialLabels)
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
                
                Section {
                    ForEach(0..<sets, id: \.self) { index in
                        HStack {
                            Text("Set \(index + 1)")
                            Spacer()
                            
                            // Label picker for each set
                            Menu {
                                Button("None") {
                                    updateSetLabel(index: index, label: .none)
                                }
                                Button("Warmup") {
                                    updateSetLabel(index: index, label: .warmup)
                                }
                                Button("Drop Set") {
                                    updateSetLabel(index: index, label: .dropSet)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(getSetLabel(index: index).rawValue)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Set Labels (Optional)")
                } footer: {
                    Text("Assign labels to specific sets (e.g., mark first 2 sets as warmup)")
                }
            }
            .navigationTitle("Edit Exercise")
            .onChange(of: sets) { oldValue, newValue in
                adjustLabelsArray(newCount: newValue)
            }
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
                    .presentationDragIndicator(.hidden)
                    .interactiveDismissDisabled(false)
                    .presentationCornerRadius(0)
                    .presentationBackground(.clear)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                }
            }
        }
    }
    
    private func saveExercise() {
        templateExercise.defaultSets = sets
        templateExercise.defaultReps = reps
        templateExercise.defaultWeight = hasWeight ? weight : nil
        templateExercise.setDefaultLabels(setLabels)
        
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
    
    private func getSetLabel(index: Int) -> SetLabel {
        guard index < setLabels.count else { return .none }
        return setLabels[index]
    }
    
    private func updateSetLabel(index: Int, label: SetLabel) {
        guard index < setLabels.count else { return }
        setLabels[index] = label
    }
    
    private func adjustLabelsArray(newCount: Int) {
        if newCount > setLabels.count {
            // Add .none labels for new sets
            while setLabels.count < newCount {
                setLabels.append(.none)
            }
        } else if newCount < setLabels.count {
            // Remove excess labels
            setLabels = Array(setLabels.prefix(newCount))
        }
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
