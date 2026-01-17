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
    
    private var duration: TimeInterval {
        guard let completedAt = workout.completedAt else { return 0 }
        return viewModel.calculateDuration(startedAt: workout.startedAt, completedAt: completedAt)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
}

struct HistoricalExerciseSectionView: View {
    let entry: WorkoutEntry
    let preferredUnits: Units
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.exercise?.name ?? "Unknown Exercise")
                .font(.headline)
                .padding(.horizontal, 4)
            
            let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
            ForEach(sets) { set in
                HistoricalSetRowView(set: set, preferredUnits: preferredUnits)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct HistoricalSetRowView: View {
    let set: SetRecord
    let preferredUnits: Units
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon (checkmark for completed, dash for skipped)
            if set.isCompleted {
                Image(systemName: "checkmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .frame(width: 20)
            } else {
                Image(systemName: "minus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            
            // Set label
            Text("Set \(set.setNumber)")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Weight and reps or skipped
            if set.isCompleted {
                if let weight = set.weight, let reps = set.reps {
                    let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
                    let unit = preferredUnits == .kg ? "kg" : "lbs"
                    Text("\(displayWeight, specifier: "%.1f") \(unit) × \(reps)")
                        .font(.body)
                        .foregroundStyle(.primary)
                } else if let reps = set.reps {
                    Text("\(reps) reps")
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text("—")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Incomplete/skipped set
                Text("skipped")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
