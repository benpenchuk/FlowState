//
//  ExerciseSectionView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/16/26.
//

import SwiftUI
import SwiftData

struct ExerciseSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: WorkoutEntry
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    var onSetCompleted: (() -> Void)? = nil
    var preferredUnits: Units = .lbs
    
    @State private var showingDeleteExerciseAlert = false
    @State private var showingDeleteLastSetAlert = false
    @State private var pendingSetIndex: Int? = nil
    @State private var showingNotes: Bool = false
    @State private var showingInstructions: Bool = false
    @State private var notesText: String = ""
    @State private var showingReorderSets = false
    @State private var showingExerciseDetails = false
    @State private var showingExerciseHistory = false
    @State private var lastSessionSets: [SetRecord] = []

    private var isCollapsed: Bool {
        viewModel.isEntryCollapsed(entry.id)
    }
    
    private var equipmentIcon: String? {
        guard let exercise = entry.exercise,
              let primaryEquipment = exercise.equipment.first else {
            return nil
        }
        return equipmentIconMapping(for: primaryEquipment)
    }
    
    private func equipmentIconMapping(for equipment: Equipment) -> String? {
        switch equipment {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .cable: return "cable.connector"
        case .machine: return "figure.strengthtraining.functional"
        case .bodyweight: return "figure.flexibility"
        case .kettlebell: return "figure.strengthtraining.traditional"
        case .resistanceBand: return "figure.strengthtraining.functional"
        case .ezBar, .trapBar: return "figure.strengthtraining.traditional"
        case .smithMachine: return "figure.strengthtraining.functional"
        case .pullupBar: return "figure.flexibility"
        case .dipBars: return "figure.flexibility"
        case .bench, .inclineBench, .declineBench: return "figure.strengthtraining.functional"
        case .treadmill: return "figure.run"
        case .bike: return "bicycle"
        case .rowingMachine: return "figure.rower"
        case .elliptical, .stairClimber: return "figure.step.training"
        case .jumpRope: return "figure.jumprope"
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        viewModel.toggleEntryCollapsed(entry.id)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if let iconName = equipmentIcon {
                            Image(systemName: iconName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                        }
                        
                        Text(entry.exercise?.name ?? "Unknown Exercise")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        if allSetsCompleted && !sets.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCollapsed ? "Expand exercise" : "Collapse exercise")
                
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        viewModel.toggleEntryCollapsed(entry.id)
                    }
                } label: {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
                
                Menu {
                    Button { showingExerciseDetails = true } label: {
                        Label("Exercise Info", systemImage: "info.circle")
                    }
                    
                    if sets.count > 1 {
                        Button { showingReorderSets = true } label: {
                            Label("Reorder Sets", systemImage: "arrow.up.arrow.down")
                        }
                    }
                    
                    Button(role: .destructive) { showingDeleteExerciseAlert = true } label: {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            if !isCollapsed {
                if !sets.isEmpty {
                    // Column Headers
                    HStack(spacing: 0) {
                        // Space for set number (22) + spacing (8) = 30
                        Color.clear.frame(width: 30)
                        
                        Text("WEIGHT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        // Matching the "×" separator space: spacing(6) + "×" (~12) + spacing(6) = ~24
                        Color.clear.frame(width: 24)
                        
                        Text("REPS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        // Space for spacing(8) + label indicator (22) + spacing(8) + checkmark (40) = 78
                        Color.clear.frame(width: 78)
                    }
                    .padding(.horizontal, 8) // Match SetRowView padding
                    .padding(.bottom, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            // Try to match by set number first, then fall back to index if needed
                            let lastSet = lastSessionSets.first(where: { $0.setNumber == set.setNumber }) ?? 
                                         (index < lastSessionSets.count ? lastSessionSets[index] : nil)
                            
                            VStack(spacing: 0) {
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
                                            // Temporarily disabled auto-advance scrolling
                                            // viewModel.autoAdvance(from: entry, completedSet: updatedSet)
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
                                
                                if index < sets.count - 1 {
                                    Divider()
                                        .padding(.leading, 30) // Align with set number
                                }
                            }
                        }
                    }
                }
                
                Button {
                    viewModel.addSetToEntry(entry)
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.top, 4)
                
                // Instructions & Notes
                VStack(spacing: 0) {
                    Divider().padding(.vertical, 8)
                    
                    HStack(spacing: 16) {
                        Button {
                            withAnimation { 
                                showingInstructions.toggle()
                                if showingInstructions { showingNotes = false }
                            }
                        } label: {
                            Label("Instructions", systemImage: "book")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(showingInstructions ? .orange : .secondary)
                        }
                        
                        Button {
                            withAnimation { 
                                showingNotes.toggle()
                                if showingNotes { 
                                    showingInstructions = false
                                    if notesText.isEmpty { notesText = entry.notes ?? "" }
                                }
                            }
                        } label: {
                            Label("Notes", systemImage: "pencil.and.outline")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(showingNotes ? .blue : .secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if showingInstructions {
                        VStack(alignment: .leading, spacing: 8) {
                            if !instructions.setup.isEmpty {
                                Text("Setup").font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                                Text(instructions.setup).font(.subheadline)
                            }
                            if !instructions.execution.isEmpty {
                                Text("Execution").font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                                Text(instructions.execution).font(.subheadline)
                            }
                            if instructions.setup.isEmpty && instructions.execution.isEmpty && instructions.tips.isEmpty {
                                Text("No instructions available.").font(.subheadline).foregroundStyle(.secondary).italic()
                            }
                        }
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    if showingNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $notesText)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.subheadline)
                            
                            HStack {
                                Spacer()
                                Button("Save") {
                                    viewModel.updateExerciseNotes(in: entry, notes: notesText.isEmpty ? nil : notesText)
                                    withAnimation { showingNotes = false }
                                    hideKeyboard()
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                            }
                        }
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius, style: .continuous)
                .stroke(
                    Color(.systemGray5),
                    lineWidth: 1
                )
        )
        .shadow(
            color: (colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.08)),
            radius: 10,
            x: 0,
            y: 4
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isCollapsed)
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
        .sheet(isPresented: $showingReorderSets) {
            ReorderSetsSheet(entry: entry, viewModel: viewModel, preferredUnits: preferredUnits)
        }
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
