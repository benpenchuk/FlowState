//
//  WorkoutHistoryDetailView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    @ObservedObject var viewModel: HistoryViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingDeleteAlert = false
    @State private var showingTemplateSavedAlert = false
    @State private var showingTemplateSaveErrorAlert = false
    @State private var templateSaveErrorMessage = ""
    
    private var duration: TimeInterval {
        guard let completedAt = workout.completedAt else { return 0 }
        return viewModel.calculateDuration(startedAt: workout.startedAt, completedAt: completedAt)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ActiveWorkoutLayout.workoutSectionSpacing) {
                // Header info
                headerSection
                
                // Exercises
                if let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty {
                    ForEach(entries) { entry in
                        HistoricalExerciseSectionView(
                            entry: entry,
                            preferredUnits: profileViewModel.profile?.units ?? .lbs
                        )
                    }
                } else {
                    Text("No exercises")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(workout.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        saveAsTemplate()
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    
                    ShareLink(item: viewModel.formatWorkoutForExport(workout, preferredUnits: profileViewModel.profile?.units ?? .lbs)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteWorkout(workout)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
        .alert("Template Saved", isPresented: $showingTemplateSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Saved as a new template.")
        }
        .alert("Couldn't Save Template", isPresented: $showingTemplateSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(templateSaveErrorMessage)
        }
        .onAppear {
            profileViewModel.setModelContext(modelContext)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header info with Date
            if let completedAt = workout.completedAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(completedAt, format: .dateTime.weekday(.wide).month().day().year())
                    Text("•")
                    Text(completedAt, format: .dateTime.hour().minute())
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    InfoBadge(
                        icon: "clock",
                        title: "Duration",
                        value: viewModel.formatDuration(duration)
                    )
                    
                    InfoBadge(
                        icon: "dumbbell",
                        title: "Exercises",
                        value: "\(workout.entries?.count ?? 0)"
                    )
                    
                    InfoBadge(
                        icon: "checkmark.circle",
                        title: "Sets",
                        value: "\(viewModel.countCompletedSets(in: workout))"
                    )
                    
                    if let volumeText = viewModel.formatVolume(workout.totalVolume, preferredUnits: profileViewModel.profile?.units ?? .lbs) {
                        InfoBadge(
                            icon: "scalemass",
                            title: "Volume",
                            value: volumeText
                        )
                    }
                    
                    if let effortRating = workout.effortRating {
                        InfoBadge(
                            icon: "gauge.with.needle",
                            title: "Effort",
                            value: "\(effortRating)/10"
                        )
                    }
                    
                    if let totalRestTime = workout.totalRestTime, totalRestTime > 0 {
                        InfoBadge(
                            icon: "pause.circle",
                            title: "Total Rest",
                            value: formatRestTime(totalRestTime)
                        )
                    }
                }
            }
            
            // Notes
            if let notes = workout.notes, !notes.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(notes)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 0.8)
        )
    }
    
    
    private func formatRestTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
        }
    }
    
    private func saveAsTemplate() {
        let baseName = workout.name ?? "Workout"
        let template = WorkoutTemplate(name: "\(baseName) (Copy)", createdAt: Date())
        modelContext.insert(template)
        
        let entries = (workout.entries ?? []).sorted { $0.order < $1.order }
        var templateExercises: [TemplateExercise] = []
        templateExercises.reserveCapacity(entries.count)
        
        for entry in entries {
            guard let exercise = entry.exercise else { continue }
            let setCount = entry.getSets().count
            let templateExercise = TemplateExercise(
                exercise: exercise,
                order: entry.order,
                defaultSets: setCount,
                defaultReps: 10,
                defaultWeight: nil
            )
            templateExercise.template = template
            modelContext.insert(templateExercise)
            templateExercises.append(templateExercise)
        }
        
        template.exercises = templateExercises
        
        do {
            try modelContext.save()
            showingTemplateSavedAlert = true
        } catch {
            templateSaveErrorMessage = error.localizedDescription
            showingTemplateSaveErrorAlert = true
        }
    }
}

struct HistoricalExerciseSectionView: View {
    let entry: WorkoutEntry
    let preferredUnits: Units
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.exercise?.category.uppercased() ?? "EXERCISE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.exercise?.name ?? "Unknown Exercise")
                        .font(.headline)
                }
                
                Spacer()
                
                if entry.totalVolume > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Volume")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text(formatVolume(entry.totalVolume))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            
            Divider()
                .opacity(0.5)
            
            let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
            VStack(spacing: 0) {
                ForEach(sets) { set in
                    HistoricalSetRowView(set: set, preferredUnits: preferredUnits)
                    
                    if set.id != sets.last?.id {
                        Divider()
                            .padding(.leading, 44) // Align with the start of the set number text
                            .opacity(0.3)
                    }
                }
            }
            
            // Exercise Notes
            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Label("Notes", systemImage: "note.text")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(ActiveWorkoutLayout.exerciseCardPadding)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 0.8)
        )
    }
    
    private func formatVolume(_ volumeInLbs: Double) -> String {
        let displayVolume = preferredUnits == .kg ? volumeInLbs / 2.20462 : volumeInLbs
        let unit = preferredUnits == .kg ? "kg" : "lbs"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let formatted = formatter.string(from: NSNumber(value: displayVolume)) ?? "\(Int(displayVolume))"
        return "\(formatted) \(unit)"
    }
}

struct HistoricalSetRowView: View {
    let set: SetRecord
    let preferredUnits: Units
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Label Badge or Status icon
            ZStack {
                if set.label != .none {
                    Text(labelInitial(for: set.label))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(labelColor(for: set.label))
                        .clipShape(Circle())
                } else {
                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .frame(width: 24)
            
            // Set number
            Text("Set \(set.setNumber)")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)
            
            // Weight and reps or skipped
            Group {
                if set.isCompleted {
                    HStack(spacing: 4) {
                        if let weight = set.weight, let reps = set.reps {
                            let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
                            let unit = preferredUnits == .kg ? "kg" : "lbs"
                            
                            let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0 ? 
                                String(format: "%.0f", displayWeight) : 
                                String(format: "%.1f", displayWeight)
                            
                            Text(weightStr)
                                .font(.body.monospacedDigit())
                                .fontWeight(.semibold)
                            
                            Text(unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("×")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                            
                            Text("\(reps)")
                                .font(.body.monospacedDigit())
                                .fontWeight(.semibold)
                            
                            Text("reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let reps = set.reps {
                            Text("\(reps)")
                                .font(.body.monospacedDigit())
                                .fontWeight(.semibold)
                            Text("reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("skipped")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
    
    private func labelInitial(for label: SetLabel) -> String {
        switch label {
        case .warmup: return "W"
        case .dropSet: return "D"
        case .none: return ""
        }
    }
    
    private func labelColor(for label: SetLabel) -> Color {
        switch label {
        case .warmup: return .cyan
        case .dropSet: return .purple
        case .none: return .gray
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryDetailView(
            workout: Workout(name: "Push Day", startedAt: Date().addingTimeInterval(-3600), completedAt: Date()),
            viewModel: HistoryViewModel()
        )
        .modelContainer(for: [Workout.self, WorkoutEntry.self, Exercise.self], inMemory: true)
    }
}
