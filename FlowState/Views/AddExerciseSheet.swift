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
    @State private var selectedExerciseType: ExerciseType = .strength
    @State private var selectedCategory: String = "Chest"
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var primaryMuscles: [String] = []
    @State private var secondaryMuscles: [String] = []
    @State private var setupInstructions: String = ""
    @State private var executionInstructions: String = ""
    @State private var tipsInstructions: String = ""
    @State private var showingEquipmentPicker = false
    @State private var showingMusclePicker = false
    @State private var isPrimaryMuscle = true
    
    // Strength categories
    private let strengthCategories = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
    
    // Cardio categories
    private let cardioCategories = ["Running", "Cycling", "Rowing", "Stair Climber", "Jump Rope", "Swimming", "Walking", "HIIT"]
    
    // Available muscles
    private let allMuscles = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms",
        "Quadriceps", "Hamstrings", "Glutes", "Calves", "Abs", "Obliques"
    ]
    
    var availableCategories: [String] {
        selectedExerciseType == .strength ? strengthCategories : cardioCategories
    }
    
    var availableEquipment: [Equipment] {
        switch selectedExerciseType {
        case .strength:
            return [.barbell, .dumbbell, .cable, .machine, .bodyweight, .kettlebell, .resistanceBand, .ezBar, .trapBar, .smithMachine, .pullupBar, .dipBars, .bench, .inclineBench, .declineBench]
        case .cardio:
            return [.treadmill, .bike, .rowingMachine, .elliptical, .stairClimber, .jumpRope, .none]
        }
    }
    
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
                    Picker("Exercise Type", selection: $selectedExerciseType) {
                        Text("Strength").tag(ExerciseType.strength)
                        Text("Cardio").tag(ExerciseType.cardio)
                    }
                    .onChange(of: selectedExerciseType) { _, _ in
                        // Reset category to first option when type changes
                        selectedCategory = availableCategories.first ?? ""
                        selectedEquipment.removeAll()
                    }
                } header: {
                    Text("Type")
                }
                
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                Section {
                    Button {
                        showingEquipmentPicker = true
                    } label: {
                        HStack {
                            Text("Equipment")
                            Spacer()
                            if selectedEquipment.isEmpty {
                                Text("None selected")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedEquipment.count) selected")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Equipment")
                } footer: {
                    if !selectedEquipment.isEmpty {
                        Text(selectedEquipment.map { equipmentDisplayName($0) }.joined(separator: ", "))
                            .font(.caption)
                    }
                }
                
                if selectedExerciseType == .strength {
                    Section {
                        Button {
                            isPrimaryMuscle = true
                            showingMusclePicker = true
                        } label: {
                            HStack {
                                Text("Primary Muscles")
                                Spacer()
                                if primaryMuscles.isEmpty {
                                    Text("None selected")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(primaryMuscles.count) selected")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        
                        Button {
                            isPrimaryMuscle = false
                            showingMusclePicker = true
                        } label: {
                            HStack {
                                Text("Secondary Muscles")
                                Spacer()
                                if secondaryMuscles.isEmpty {
                                    Text("None selected")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(secondaryMuscles.count) selected")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    } header: {
                        Text("Muscles")
                    } footer: {
                        if !primaryMuscles.isEmpty || !secondaryMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if !primaryMuscles.isEmpty {
                                    Text("Primary: \(primaryMuscles.joined(separator: ", "))")
                                        .font(.caption)
                                }
                                if !secondaryMuscles.isEmpty {
                                    Text("Secondary: \(secondaryMuscles.joined(separator: ", "))")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    TextField("Setup instructions (optional)", text: $setupInstructions, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Execution instructions (optional)", text: $executionInstructions, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Tips (optional)", text: $tipsInstructions, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Instructions (Optional)")
                } footer: {
                    Text("Instructions are optional for custom exercises")
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
            .sheet(isPresented: $showingEquipmentPicker) {
                EquipmentMultiSelectSheet(
                    selectedEquipment: $selectedEquipment,
                    availableEquipment: availableEquipment
                )
            }
            .sheet(isPresented: $showingMusclePicker) {
                MuscleMultiSelectSheet(
                    selectedMuscles: isPrimaryMuscle ? $primaryMuscles : $secondaryMuscles,
                    allMuscles: allMuscles,
                    title: isPrimaryMuscle ? "Primary Muscles" : "Secondary Muscles"
                )
            }
        }
    }
    
    private func saveExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let instructions = ExerciseInstructions(
            setup: setupInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
            execution: executionInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
            tips: tipsInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        viewModel.addCustomExercise(
            name: trimmedName,
            exerciseType: selectedExerciseType,
            category: selectedCategory,
            equipment: Array(selectedEquipment),
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            instructions: instructions
        )
        dismiss()
    }
    
    private func equipmentDisplayName(_ equipment: Equipment) -> String {
        switch equipment {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .resistanceBand: return "Resistance Band"
        case .ezBar: return "EZ Bar"
        case .trapBar: return "Trap Bar"
        case .smithMachine: return "Smith Machine"
        case .pullupBar: return "Pull-up Bar"
        case .dipBars: return "Dip Bars"
        case .bench: return "Bench"
        case .inclineBench: return "Incline Bench"
        case .declineBench: return "Decline Bench"
        case .treadmill: return "Treadmill"
        case .bike: return "Bike"
        case .rowingMachine: return "Rowing Machine"
        case .elliptical: return "Elliptical"
        case .stairClimber: return "Stair Climber"
        case .jumpRope: return "Jump Rope"
        case .none: return "None"
        }
    }
}

struct EquipmentMultiSelectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEquipment: Set<Equipment>
    let availableEquipment: [Equipment]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableEquipment, id: \.self) { equipment in
                    Button {
                        if selectedEquipment.contains(equipment) {
                            selectedEquipment.remove(equipment)
                        } else {
                            selectedEquipment.insert(equipment)
                        }
                    } label: {
                        HStack {
                            Text(equipmentDisplayName(equipment))
                            Spacer()
                            if selectedEquipment.contains(equipment) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        selectedEquipment.removeAll()
                    }
                    .disabled(selectedEquipment.isEmpty)
                }
            }
        }
    }
    
    private func equipmentDisplayName(_ equipment: Equipment) -> String {
        switch equipment {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .resistanceBand: return "Resistance Band"
        case .ezBar: return "EZ Bar"
        case .trapBar: return "Trap Bar"
        case .smithMachine: return "Smith Machine"
        case .pullupBar: return "Pull-up Bar"
        case .dipBars: return "Dip Bars"
        case .bench: return "Bench"
        case .inclineBench: return "Incline Bench"
        case .declineBench: return "Decline Bench"
        case .treadmill: return "Treadmill"
        case .bike: return "Bike"
        case .rowingMachine: return "Rowing Machine"
        case .elliptical: return "Elliptical"
        case .stairClimber: return "Stair Climber"
        case .jumpRope: return "Jump Rope"
        case .none: return "None"
        }
    }
}

struct MuscleMultiSelectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMuscles: [String]
    let allMuscles: [String]
    let title: String
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allMuscles, id: \.self) { muscle in
                    Button {
                        if let index = selectedMuscles.firstIndex(of: muscle) {
                            selectedMuscles.remove(at: index)
                        } else {
                            selectedMuscles.append(muscle)
                        }
                    } label: {
                        HStack {
                            Text(muscle)
                            Spacer()
                            if selectedMuscles.contains(muscle) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        selectedMuscles.removeAll()
                    }
                    .disabled(selectedMuscles.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddExerciseSheet(viewModel: ExerciseLibraryViewModel())
}
