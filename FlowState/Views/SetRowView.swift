//
//  SetRowView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct SetRowView: View {
    let set: SetRecord
    let onUpdate: (SetRecord, Int?, Double?, Bool) -> Void
    let onDelete: () -> Void
    let onLabelUpdate: ((SetRecord, SetLabel) -> Void)?
    let preferredUnits: Units
    
    @State private var repsText: String
    @State private var weightText: String
    @State private var showingNumPad = false
    @State private var editingField: Field?
    @State private var numPadValue: String = ""
    @State private var showingLabelPicker = false
    
    enum Field {
        case weight, reps
    }
    
    init(set: SetRecord, preferredUnits: Units = .lbs, onUpdate: @escaping (SetRecord, Int?, Double?, Bool) -> Void, onDelete: @escaping () -> Void, onLabelUpdate: ((SetRecord, SetLabel) -> Void)? = nil) {
        self.set = set
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
        ViewThatFits(in: .horizontal) {
            wideLayout
            compactLayout
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minHeight: 60, alignment: .center)
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

    // MARK: - Layout (responsive)

    private var wideLayout: some View {
        HStack(spacing: 10) {
            dragHandle
            setNumber

            weightField(compact: false)

            Text("×")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            repsField(compact: false)

            Spacer(minLength: 0)
            labelIndicator
            completionButton
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 8) {
            dragHandle
            setNumber

            weightField(compact: true)
            repsField(compact: true)

            Spacer(minLength: 0)
            labelIndicator
            completionButton
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.6))
            .frame(width: 24, height: 44)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }

    private var setNumber: some View {
        Text("\(set.setNumber)")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .frame(minWidth: 26, alignment: .center)
            .accessibilityLabel("Set \(set.setNumber)")
    }

    private func weightField(compact: Bool) -> some View {
        Button {
            editingField = .weight
            numPadValue = weightText.isEmpty ? "" : weightText
            showingNumPad = true
        } label: {
            fieldBox(
                value: weightText,
                placeholder: "0.0",
                subtitle: preferredUnits.rawValue,
                isActive: showingNumPad && editingField == .weight,
                compact: compact
            )
        }
        .buttonStyle(.plain)
        .layoutPriority(compact ? 1 : 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Weight")
    }

    private func repsField(compact: Bool) -> some View {
        Button {
            editingField = .reps
            numPadValue = repsText.isEmpty ? "" : repsText
            showingNumPad = true
        } label: {
            fieldBox(
                value: repsText,
                placeholder: "0",
                subtitle: "reps",
                isActive: showingNumPad && editingField == .reps,
                compact: compact
            )
        }
        .buttonStyle(.plain)
        .layoutPriority(compact ? 1 : 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Reps")
    }

    private func fieldBox(
        value: String,
        placeholder: String,
        subtitle: String,
        isActive: Bool,
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 2) {
            Text(value.isEmpty ? placeholder : value)
                .font(.system(size: compact ? 18 : 20, weight: .semibold, design: .default))
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 10 : 12)
        .padding(.horizontal, compact ? 10 : 12)
        .background(isActive ? Color.orange.opacity(0.15) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.orange : Color.clear, lineWidth: 2)
        )
        .cornerRadius(10)
        .contentShape(Rectangle())
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
    List {
        SetRowView(
            set: SetRecord(setNumber: 1, reps: 10, weight: 135, isCompleted: false, label: .warmup),
            preferredUnits: .lbs,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
        
        SetRowView(
            set: SetRecord(setNumber: 2, reps: 10, weight: 135, isCompleted: true, label: .failure),
            preferredUnits: .kg,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
        
        SetRowView(
            set: SetRecord(setNumber: 3, reps: 8, weight: 185, isCompleted: false, label: .prAttempt),
            preferredUnits: .lbs,
            onUpdate: { _, _, _, _ in },
            onDelete: {},
            onLabelUpdate: { _, _ in }
        )
    }
}
