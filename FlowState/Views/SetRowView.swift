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
    
    @State private var repsText: String
    @State private var weightText: String
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    init(set: SetRecord, onUpdate: @escaping (SetRecord, Int?, Double?, Bool) -> Void, onDelete: @escaping () -> Void) {
        self.set = set
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
        _weightText = State(initialValue: set.weight.map { String(format: "%.1f", $0) } ?? "")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(set.setNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
            
            // Weight input
            TextField("0.0", text: $weightText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { oldValue, newValue in
                    let weight = Double(newValue)
                    onUpdate(set, set.reps, weight, set.isCompleted)
                }
            
            Text("×")
                .foregroundStyle(.secondary)
            
            // Reps input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { oldValue, newValue in
                    let reps = Int(newValue)
                    onUpdate(set, reps, set.weight, set.isCompleted)
                }
            
            Spacer()
            
            // Completion button
            Button {
                onUpdate(set, set.reps, set.weight, !set.isCompleted)
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(set.isCompleted ? Color(.systemGray6) : Color.clear)
        .cornerRadius(8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    List {
        SetRowView(
            set: SetRecord(setNumber: 1, reps: 10, weight: 135, isCompleted: false),
            onUpdate: { _, _, _, _ in },
            onDelete: {}
        )
        
        SetRowView(
            set: SetRecord(setNumber: 2, reps: 10, weight: 135, isCompleted: true),
            onUpdate: { _, _, _, _ in },
            onDelete: {}
        )
    }
}
