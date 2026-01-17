//
//  ExerciseSectionView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/16/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExerciseSectionView: View {
    let entry: WorkoutEntry
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    var isActive: Bool = false
    var onSetCompleted: (() -> Void)? = nil
    var preferredUnits: Units = .lbs
    
    @State private var showingDeleteExerciseAlert = false
    @State private var showingDeleteLastSetAlert = false
    @State private var pendingSetIndex: Int? = nil
    @State private var isExpanded: Bool = true
    @State private var showingNotes: Bool = false
    @State private var showingInstructions: Bool = false
    @State private var notesText: String = ""
    @State private var draggedSetId: UUID? = nil
    @State private var dropTargetSetId: UUID? = nil
    @State private var currentDragId: UUID? = nil
    @State private var showingExerciseDetails = false
    @State private var showingExerciseHistory = false
    @State private var lastSessionSets: [SetRecord] = []
    
    private var equipmentIcon: (name: String, color: Color)? {
        guard let exercise = entry.exercise,
              let primaryEquipment = exercise.equipment.first else {
            return nil
        }
        return equipmentIconMapping(for: primaryEquipment)
    }
    
    private func equipmentIconMapping(for equipment: Equipment) -> (name: String, color: Color)? {
        switch equipment {
        case .barbell: return ("figure.strengthtraining.traditional", .orange)
        case .dumbbell: return ("dumbbell.fill", .orange)
        case .cable: return ("cable.connector", .blue)
        case .machine: return ("figure.strengthtraining.functional", .purple)
        case .bodyweight: return ("figure.flexibility", .green)
        case .kettlebell: return ("figure.strengthtraining.traditional", .orange)
        case .resistanceBand: return ("figure.strengthtraining.functional", .purple)
        case .ezBar, .trapBar: return ("figure.strengthtraining.traditional", .orange)
        case .smithMachine: return ("figure.strengthtraining.functional", .purple)
        case .pullupBar: return ("figure.flexibility", .green)
        case .dipBars: return ("figure.flexibility", .green)
        case .bench, .inclineBench, .declineBench: return ("figure.strengthtraining.functional", .purple)
        case .treadmill: return ("figure.run", .blue)
        case .bike: return ("bicycle", .blue)
        case .rowingMachine: return ("figure.rower", .blue)
        case .elliptical, .stairClimber: return ("figure.step.training", .blue)
        case .jumpRope: return ("figure.jumprope", .blue)
        case .none: return nil
        }
    }
    
    private var sets: [SetRecord] {
        entry.getSets().sorted { $0.setNumber < $1.setNumber }
    }
    
    private var allSetsCompleted: Bool {
        sets.allSatisfy { $0.isCompleted }
    }
    
    private var instructions: ExerciseInstructions {
        entry.exercise?.getInstructions() ?? ExerciseInstructions()
    }
    
    private var cardBackgroundColor: Color {
        if isActive {
            return Color.orange.opacity(0.05)
        } else if allSetsCompleted && !sets.isEmpty {
            return Color.green.opacity(0.03)
        } else {
            return Color(.systemGray6).opacity(0.5)
        }
    }
    
    private var cardStrokeColor: Color {
        if isActive {
            return Color.orange.opacity(0.5)
        } else if allSetsCompleted && !sets.isEmpty {
            return Color.green.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var cardStrokeWidth: CGFloat {
        isActive ? 2 : 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise header
            HStack(spacing: 4) {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }
                .buttonStyle(.plain)
                
                if let icon = equipmentIcon {
                    Image(systemName: icon.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(icon.color)
                        .frame(width: 20)
                }
                
                Text(entry.exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .padding(.horizontal, 4)
                
                if allSetsCompleted && !sets.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if !isExpanded {
                    Text("\(sets.count) set\(sets.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if entry.exercise != nil {
                    Button { showingExerciseDetails = true } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Button { showingDeleteExerciseAlert = true } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if isExpanded {
                if !sets.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            // Try to match by set number first, then fall back to index if needed
                            let lastSet = lastSessionSets.first(where: { $0.setNumber == set.setNumber }) ?? 
                                         (index < lastSessionSets.count ? lastSessionSets[index] : nil)
                            
                            SetRowView(
                                viewModel: viewModel,
                                set: set,
                                lastSessionSet: lastSet,
                                preferredUnits: preferredUnits,
                                onUpdate: { updatedSet, reps, weight, isCompleted in
                                    let wasCompleted = updatedSet.isCompleted
                                    viewModel.updateSet(in: entry, set: updatedSet, reps: reps, weight: weight, isCompleted: isCompleted)
                                    if !wasCompleted && isCompleted { 
                                        onSetCompleted?()
                                        viewModel.autoAdvance(from: entry, completedSet: updatedSet)
                                    }
                                },
                                onDelete: {
                                    let allSets = entry.getSets()
                                    if let actualIndex = allSets.firstIndex(where: { $0.id == set.id }) {
                                        if allSets.count == 1 {
                                            pendingSetIndex = actualIndex
                                            showingDeleteLastSetAlert = true
                                        } else {
                                            viewModel.deleteSet(from: entry, at: actualIndex)
                                        }
                                    }
                                },
                                onLabelUpdate: { updatedSet, label in
                                    viewModel.updateSetLabel(in: entry, set: updatedSet, label: label)
                                }
                            )
                            .id(set.id)
                            .contentShape(Rectangle())
                            .opacity(draggedSetId == set.id ? 0.5 : 1.0)
                            .overlay(
                                Group {
                                    if dropTargetSetId == set.id && draggedSetId != set.id {
                                        RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                                            .stroke(Color.orange, lineWidth: 2)
                                            .padding(-4)
                                    }
                                }
                            )
                            .onDrag {
                                draggedSetId = set.id
                                currentDragId = set.id
                                let uuidString = set.id.uuidString
                                let itemProvider = NSItemProvider()
                                itemProvider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
                                    completion(uuidString.data(using: .utf8), nil)
                                    return nil
                                }
                                return itemProvider
                            } preview: {
                                SetRowView(viewModel: viewModel, set: set, preferredUnits: preferredUnits, onUpdate: { _, _, _, _ in }, onDelete: {}, onLabelUpdate: nil)
                                    .frame(width: 350)
                                    .background(Color(.systemBackground))
                            }
                            .onDrop(of: [.text], delegate: SetDropDelegate(
                                destinationSet: set,
                                sets: sets,
                                entry: entry,
                                viewModel: viewModel,
                                draggedSetId: $draggedSetId,
                                dropTargetSetId: $dropTargetSetId,
                                currentDragId: $currentDragId
                            ))
                        }
                    }
                }
                
                Button {
                    viewModel.addSetToEntry(entry)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Set")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation { showingInstructions.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: showingInstructions ? "book.fill" : "book")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            Text("Instructions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            if !instructions.setup.isEmpty || !instructions.execution.isEmpty || !instructions.tips.isEmpty {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingInstructions {
                        VStack(alignment: .leading, spacing: 12) {
                            if !instructions.setup.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Setup").font(.body).fontWeight(.semibold)
                                    Text(instructions.setup).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if !instructions.execution.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Execution").font(.body).fontWeight(.semibold)
                                    Text(instructions.execution).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if !instructions.tips.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tips").font(.body).fontWeight(.semibold)
                                    Text(instructions.tips).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if instructions.setup.isEmpty && instructions.execution.isEmpty && instructions.tips.isEmpty {
                                Text("No instructions available.").font(.body).foregroundStyle(.secondary).italic()
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray5).opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation {
                            showingNotes.toggle()
                            if showingNotes && notesText.isEmpty { notesText = entry.notes ?? "" }
                        }
                    } label: {
                        HStack {
                            Image(systemName: showingNotes ? "note.text" : "note")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            if !(entry.notes?.isEmpty ?? true) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $notesText)
                                .frame(minHeight: 60, maxHeight: 120)
                                .cornerRadius(8)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .font(.body)
                                .accessibilityLabel("Exercise notes")
                                .onAppear {
                                    // Avoid double assignment if already loaded
                                    if notesText.isEmpty { notesText = entry.notes ?? "" }
                                }
                            HStack {
                                Spacer()
                                Button(action: {
                                    viewModel.updateExerciseNotes(in: entry, notes: notesText.isEmpty ? nil : notesText)
                                    withAnimation { showingNotes = false }
                                    hideKeyboard()
                                }) {
                                    Text("Done")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .accessibilityLabel("Save notes and close")
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .stroke(cardStrokeColor, lineWidth: cardStrokeWidth)
        )
        .onAppear { 
            notesText = entry.notes ?? "" 
            if let exercise = entry.exercise {
                lastSessionSets = viewModel.getLastSessionSets(for: exercise)
            }
        }
        .alert("Remove Exercise", isPresented: $showingDeleteExerciseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { viewModel.deleteExercise(entry) }
        } message: {
            Text("Remove \(entry.exercise?.name ?? "this exercise") from workout?")
        }
        .alert("Delete Last Set", isPresented: $showingDeleteLastSetAlert) {
            Button("Cancel", role: .cancel) { pendingSetIndex = nil }
            Button("Delete Exercise", role: .destructive) {
                if let index = pendingSetIndex { viewModel.deleteSet(from: entry, at: index) }
                pendingSetIndex = nil
            }
        } message: {
            Text("This is the last set. Delete this exercise from your workout?")
        }
        .sheet(isPresented: $showingExerciseDetails) {
            if let exercise = entry.exercise {
                ExerciseInfoSheet(exercise: exercise, preferredUnits: preferredUnits, showingHistory: $showingExerciseHistory)
            }
        }
        .sheet(isPresented: $showingExerciseHistory) {
            if let exercise = entry.exercise {
                ExerciseHistorySheet(exercise: exercise, preferredUnits: preferredUnits)
            }
        }
    }
}

// Support Structures
struct SetDropDelegate: DropDelegate {
    let destinationSet: SetRecord
    let sets: [SetRecord]
    let entry: WorkoutEntry
    let viewModel: ActiveWorkoutViewModel
    @Binding var draggedSetId: UUID?
    @Binding var dropTargetSetId: UUID?
    @Binding var currentDragId: UUID?
    
    func performDrop(info: DropInfo) -> Bool {
        if let sourceId = currentDragId {
            performReorder(sourceId: sourceId)
        }
        dropTargetSetId = nil
        draggedSetId = nil
        currentDragId = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let sourceId = currentDragId {
            performReorder(sourceId: sourceId, showFeedback: true)
        }
    }
    
    private func performReorder(sourceId: UUID, showFeedback: Bool = false) {
        guard let sourceIndex = sets.firstIndex(where: { $0.id == sourceId }),
              let destinationIndex = sets.firstIndex(where: { $0.id == destinationSet.id }),
              sourceIndex != destinationIndex else { return }
        
        if showFeedback { dropTargetSetId = destinationSet.id }
        
        let adjustedDestination = (sourceIndex < destinationIndex && destinationIndex == sets.count - 1) ? sets.count : destinationIndex
        viewModel.reorderSets(in: entry, from: IndexSet(integer: sourceIndex), to: adjustedDestination)
    }
}

struct ExerciseInfoSheet: View {
    let exercise: Exercise
    let preferredUnits: Units
    @Binding var showingHistory: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressViewModel = ProgressViewModel()
    
    private var instructions: ExerciseInstructions { exercise.getInstructions() }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name).font(.title2).fontWeight(.bold)
                        Text(exercise.category).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    instructionsSection
                    
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showingHistory = true }
                    } label: {
                        Label("View Exercise History", systemImage: "clock.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear { progressViewModel.setModelContext(modelContext) }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Instructions", systemImage: "book.fill").font(.headline)
            let inst = instructions
            if !inst.setup.isEmpty || !inst.execution.isEmpty || !inst.tips.isEmpty {
                if !inst.setup.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Setup").font(.subheadline).fontWeight(.semibold)
                        Text(inst.setup).font(.body).foregroundStyle(.secondary)
                    }
                }
                if !inst.execution.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Execution").font(.subheadline).fontWeight(.semibold)
                        Text(inst.execution).font(.body).foregroundStyle(.secondary)
                    }
                }
                if !inst.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips").font(.subheadline).fontWeight(.semibold)
                        Text(inst.tips).font(.body).foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No instructions available.").font(.body).foregroundStyle(.secondary).italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ExerciseHistorySheet: View {
    let exercise: Exercise
    let preferredUnits: Units
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressViewModel = ProgressViewModel()
    @State private var currentPR: PersonalRecord? = nil
    @State private var history: [(date: Date, maxWeight: Double, sets: [SetRecord])] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(exercise.name).font(.title2).fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    if let pr = currentPR {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Personal Record", systemImage: "star.fill").foregroundStyle(.yellow).font(.headline)
                            HStack {
                                VStack(alignment: .leading) {
                                    let weight = preferredUnits == .kg ? pr.weight / 2.20462 : pr.weight
                                    Text("\(String(format: "%.1f", weight)) \(preferredUnits == .kg ? "kg" : "lbs")").font(.title).fontWeight(.bold)
                                    Text("× \(pr.reps) reps").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(pr.achievedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Recent History", systemImage: "clock.fill").font(.headline)
                            ForEach(history.prefix(5).indices, id: \.self) { i in
                                MiniHistoryRowView(date: history[i].date, maxWeight: history[i].maxWeight, sets: history[i].sets, preferredUnits: preferredUnits)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear {
                progressViewModel.setModelContext(modelContext)
                currentPR = progressViewModel.calculatePR(for: exercise)
                history = progressViewModel.getExerciseHistory(for: exercise, limit: 5)
            }
        }
    }
}

struct MiniHistoryRowView: View {
    let date: Date
    let maxWeight: Double
    let sets: [SetRecord]
    let preferredUnits: Units
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date, style: .date).font(.subheadline).fontWeight(.semibold)
                Spacer()
                let weight = preferredUnits == .kg ? maxWeight / 2.20462 : maxWeight
                Text("\(String(format: "%.1f", weight)) \(preferredUnits == .kg ? "kg" : "lbs")").font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(sets.prefix(5)) { set in
                    if let w = set.weight, let r = set.reps {
                        let displayW = preferredUnits == .kg ? w / 2.20462 : w
                        Text("\(String(format: "%.1f", displayW))×\(r)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
