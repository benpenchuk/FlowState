//
//  ReorderSetsSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/20/26.
//

import SwiftUI

struct ReorderSetsSheet: View {
    let entry: WorkoutEntry
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    let preferredUnits: Units

    @Environment(\.dismiss) private var dismiss

    @State private var orderedSetIds: [UUID]

    init(entry: WorkoutEntry, viewModel: ActiveWorkoutViewModel, preferredUnits: Units = .lbs) {
        self.entry = entry
        self.viewModel = viewModel
        self.preferredUnits = preferredUnits

        let initialSets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
        _orderedSetIds = State(initialValue: initialSets.map(\.id))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(orderedSetIds.enumerated()), id: \.element) { index, id in
                        if let set = setById(id) {
                            row(for: set, displaySetNumber: index + 1)
                        }
                    }
                    .onMove(perform: move)
                } footer: {
                    Text("Drag the handles to reorder sets. This only changes the set order within this exercise.")
                }
            }
            // Always show reorder controls.
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Sets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        orderedSetIds.move(fromOffsets: source, toOffset: destination)
        viewModel.applySetOrder(in: entry, orderedSetIds: orderedSetIds)
    }

    private func setById(_ id: UUID) -> SetRecord? {
        entry.getSets().first(where: { $0.id == id })
    }

    @ViewBuilder
    private func row(for set: SetRecord, displaySetNumber: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set \(displaySetNumber)")
                    .font(.system(.headline, design: .rounded))

                Text(setSummary(set))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if set.label != .none {
                Circle()
                    .fill(labelColor(for: set.label))
                    .frame(width: 8, height: 8)
            }

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.4))
                .font(.system(size: 18, weight: .semibold))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }

    private func setSummary(_ set: SetRecord) -> String {
        let unit = preferredUnits == .kg ? "kg" : "lbs"

        var parts: [String] = []

        if let weight = set.weight {
            let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
            let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", displayWeight)
                : String(format: "%.1f", displayWeight)
            parts.append("\(weightStr) \(unit)")
        }

        if let reps = set.reps {
            parts.append("\(reps) reps")
        }

        if parts.isEmpty {
            return "—"
        }

        return parts.joined(separator: " · ")
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
}

