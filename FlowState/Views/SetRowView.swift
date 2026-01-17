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
        HStack(spacing: 6) {
            dragHandle
            setNumber

            HStack(spacing: 4) {
                weightField
                
                Text("×")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                repsField
            }
            
            Spacer(minLength: 2)
            
            labelIndicator
            completionButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .frame(minHeight: 48, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(set.isCompleted ? Color(.systemGray6).opacity(0.8) : Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
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
            .presentationBackground {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
            .presentationCornerRadius(16)
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

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.4))
            .frame(width: 20, height: 44)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
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
                    subtitle: preferredUnits.rawValue,
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
                    subtitle: "reps",
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
        subtitle: String,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .center, spacing: 1) {
            Text(value.isEmpty ? placeholder : value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: 0) {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                if let last = lastSessionSet {
                    let lastValue: String = {
                        if subtitle == "reps" {
                            return "\(last.reps ?? 0)"
                        } else {
                            let displayWeight = last.weight.map { w in
                                preferredUnits == .kg ? w / 2.20462 : w
                            }
                            return displayWeight.map { String(format: "%.1f", $0) } ?? "0"
                        }
                    }()
                    
                    Text("Last: \(lastValue)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(minWidth: 48, maxWidth: 72)
        .padding(.vertical, 3)
        .padding(.horizontal, 2)
        .background(isActive ? Color.orange.opacity(0.1) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.orange : Color.clear, lineWidth: 1.5)
        )
        .cornerRadius(8)
    }

    private var labelIndicator: some View {
        Group {
            if set.label != .none {
                Circle()
                    .fill(labelColor(for: set.label))
                    .frame(width: 10, height: 10)
                    .padding(.horizontal, 6)
            } else {
                Color.clear
                    .frame(width: 10, height: 10)
                    .padding(.horizontal, 6)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showingLabelPicker = true
        }
        .accessibilityLabel("Set label")
    }

    private var completionButton: some View {
        Button {
            onUpdate(set, set.reps, set.weight, !set.isCompleted)
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(set.isCompleted ? .green : .secondary)
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isCompleted ? "Mark set incomplete" : "Mark set complete")
    }
    
    private func labelColor(for label: SetLabel) -> Color {
        switch label {
        case .none:
            return .gray.opacity(0.5)
        case .warmup:
            return .cyan
        case .failure:
            return .red
        case .dropSet:
            return .purple
        case .prAttempt:
            return .yellow
        }
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
                .frame(width: 22, height: 22)
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
            set: SetRecord(setNumber: 2, reps: 10, weight: 135, isCompleted: true, label: .failure),
            preferredUnits: .kg,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
        
        SetRowView(
            viewModel: vm,
            set: SetRecord(setNumber: 3, reps: 8, weight: 185, isCompleted: false, label: .prAttempt),
            preferredUnits: .lbs,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
    }
}
