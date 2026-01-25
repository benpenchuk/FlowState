//
//  SetRowView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct SetRowView: View {
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    let set: SetRecord
    let lastSessionSet: SetRecord?
    let onUpdate: (SetRecord, Int?, Double?, Bool) -> Void
    let onDelete: () -> Void
    let onLabelUpdate: ((SetRecord, SetLabel) -> Void)?
    let preferredUnits: Units
    
    @State private var repsText: String
    @State private var weightText: String
    @State private var showingNumPad = false
    @State private var editingField: ActiveWorkoutField?
    @State private var numPadValue: String = ""
    @State private var showingLabelPicker = false
    
    init(viewModel: ActiveWorkoutViewModel, set: SetRecord, lastSessionSet: SetRecord? = nil, preferredUnits: Units = .lbs, onUpdate: @escaping (SetRecord, Int?, Double?, Bool) -> Void, onDelete: @escaping () -> Void, onLabelUpdate: ((SetRecord, SetLabel) -> Void)? = nil) {
        self.viewModel = viewModel
        self.set = set
        self.lastSessionSet = lastSessionSet
        self.preferredUnits = preferredUnits
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onLabelUpdate = onLabelUpdate
        
        // Convert weight for display
        let displayWeight = set.weight.map { weight in
            preferredUnits == .kg ? weight / 2.20462 : weight
        }
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
        _weightText = State(initialValue: displayWeight.map { String(format: "%.1f", $0) } ?? "")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            setNumber

            HStack(spacing: 6) {
                weightField
                    .frame(maxWidth: .infinity)
                
                Text("×")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.3))
                
                repsField
                    .frame(maxWidth: .infinity)
            }
            
            labelIndicator
            completionButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .frame(minHeight: 48, alignment: .center)
        .background(set.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingNumPad) {
            CustomNumPadView(
                value: $numPadValue,
                showDecimal: editingField == .weight,
                fieldLabel: editingField == .weight ? "Weight" : "Reps",
                preferredUnits: editingField == .weight ? preferredUnits : nil,
                onDone: {
                    withAnimation {
                        showingNumPad = false
                    }
                    // Save after sheet starts dismissing to prevent glitch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        saveNumPadValue()
                        editingField = nil
                    }
                }
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(false)
            .presentationCornerRadius(0)
            .presentationBackground(.clear)
            .presentationBackgroundInteraction(.enabled)
            .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $showingLabelPicker) {
            LabelPickerSheet(
                currentLabel: set.label,
                onSelect: { label in
                    onLabelUpdate?(set, label)
                    showingLabelPicker = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }

    private var setNumber: some View {
        Text("\(set.setNumber)")
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .frame(width: 22, alignment: .center)
            .accessibilityLabel("Set \(set.setNumber)")
    }

    private var weightField: some View {
        HStack(spacing: 4) {
            stepperButton(systemName: "minus") { adjustWeight(by: preferredUnits == .kg ? -1.0 : -2.5) }
            
            Button {
                editingField = .weight
                numPadValue = weightText.isEmpty ? "" : weightText
                showingNumPad = true
            } label: {
                fieldBox(
                    value: weightText,
                    placeholder: "0.0",
                    isWeight: true,
                    isActive: showingNumPad && editingField == .weight
                )
            }
            .buttonStyle(.plain)
            
            stepperButton(systemName: "plus") { adjustWeight(by: preferredUnits == .kg ? 1.0 : 2.5) }
        }
    }

    private var repsField: some View {
        HStack(spacing: 4) {
            stepperButton(systemName: "minus") { adjustReps(by: -1) }
            
            Button {
                editingField = .reps
                numPadValue = repsText.isEmpty ? "" : repsText
                showingNumPad = true
            } label: {
                fieldBox(
                    value: repsText,
                    placeholder: "0",
                    isWeight: false,
                    isActive: showingNumPad && editingField == .reps
                )
            }
            .buttonStyle(.plain)
            
            stepperButton(systemName: "plus") { adjustReps(by: 1) }
        }
    }

    private func fieldBox(
        value: String,
        placeholder: String,
        isWeight: Bool,
        isActive: Bool
    ) -> some View {
        return Text(value.isEmpty ? placeholder : value)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(value.isEmpty ? Color.secondary.opacity(0.3) : (isActive ? .orange : .primary))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.orange.opacity(0.1) : Color.clear)
            .cornerRadius(8)
    }

    private var labelIndicator: some View {
        Button {
            guard onLabelUpdate != nil else { return }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showingLabelPicker = true
        } label: {
            Text(labelText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onLabelUpdate == nil)
        .accessibilityLabel(labelAccessibilityText)
        .accessibilityHint(onLabelUpdate != nil ? "Tap to change set label" : "")
    }
    
    private var labelText: String {
        switch set.label {
        case .none:
            return ""
        case .warmup:
            return "W"
        case .dropSet:
            return "D"
        }
    }
    
    private var labelAccessibilityText: String {
        switch set.label {
        case .none:
            return "No label"
        case .warmup:
            return "Warmup set"
        case .dropSet:
            return "Drop set"
        }
    }

    private var completionButton: some View {
        Button {
            onUpdate(set, set.reps, set.weight, !set.isCompleted)
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.4))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isCompleted ? "Mark set incomplete" : "Mark set complete")
    }
    
    
    private func adjustWeight(by amount: Double) {
        let currentWeight = Double(weightText) ?? 0.0
        let newWeight = max(0, currentWeight + amount)
        weightText = String(format: "%.1f", newWeight)
        
        let weightInLbs = preferredUnits == .kg ? newWeight * 2.20462 : newWeight
        onUpdate(set, set.reps, weightInLbs, set.isCompleted)
    }
    
    private func adjustReps(by amount: Int) {
        let currentReps = Int(repsText) ?? 0
        let newReps = max(0, currentReps + amount)
        repsText = "\(newReps)"
        onUpdate(set, newReps, set.weight, set.isCompleted)
    }
    
    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.orange)
                .frame(width: 24, height: 24)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func saveNumPadValue() {
        guard let field = editingField else { return }
        
        switch field {
        case .weight:
            weightText = numPadValue
            // Convert from display units to lbs for storage
            if let displayWeight = Double(numPadValue) {
                let weightInLbs = preferredUnits == .kg ? displayWeight * 2.20462 : displayWeight
                onUpdate(set, set.reps, weightInLbs, set.isCompleted)
            } else {
                onUpdate(set, set.reps, nil, set.isCompleted)
            }
        case .reps:
            repsText = numPadValue
            let reps = Int(numPadValue)
            onUpdate(set, reps, set.weight, set.isCompleted)
        }
    }
}

#Preview {
    let vm = ActiveWorkoutViewModel()
    List {
        SetRowView(
            viewModel: vm,
            set: SetRecord(setNumber: 1, reps: 10, weight: 135, isCompleted: false, label: .warmup),
            preferredUnits: .lbs,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
        
        SetRowView(
            viewModel: vm,
            set: SetRecord(setNumber: 2, reps: 10, weight: 135, isCompleted: true, label: .dropSet),
            preferredUnits: .kg,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
        
        SetRowView(
            viewModel: vm,
            set: SetRecord(setNumber: 3, reps: 8, weight: 185, isCompleted: false, label: .none),
            preferredUnits: .lbs,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
    }
}
