//
//  HistoryView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                skeletonList
            } else if viewModel.completedWorkouts.isEmpty {
                emptyStateView
            } else {
                workoutHistoryList
            }
        }
        .navigationTitle("History")
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    private var skeletonList: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonWorkoutHistoryCard()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No workout history")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Completed workouts will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var workoutHistoryList: some View {
        List {
            ForEach(viewModel.groupWorkoutsByDate(), id: \.0) { dateGroup in
                Section {
                    ForEach(dateGroup.1) { workout in
                        NavigationLink {
                            WorkoutHistoryDetailView(workout: workout, viewModel: viewModel)
                        } label: {
                            WorkoutHistoryRowView(workout: workout, viewModel: viewModel)
                        }
                    }
                } header: {
                    Text(dateGroup.0)
                }
            }
        }
    }
}

struct WorkoutHistoryRowView: View {
    let workout: Workout
    let viewModel: HistoryViewModel
    
    private var duration: TimeInterval {
        guard let completedAt = workout.completedAt else { return 0 }
        return viewModel.calculateDuration(startedAt: workout.startedAt, completedAt: completedAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name ?? "Workout")
                    .font(.headline)
                
                Spacer()
                
                if let completedAt = workout.completedAt {
                    Text(completedAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                Label(viewModel.formatDuration(duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(workout.entries?.count ?? 0) exercises", systemImage: "dumbbell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(viewModel.countCompletedSets(in: workout)) sets", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: [Workout.self, WorkoutEntry.self, Exercise.self], inMemory: true)
    }
}
