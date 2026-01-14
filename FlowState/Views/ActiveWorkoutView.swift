//
//  ActiveWorkoutView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    @State private var showingCancelAlert = false
    @State private var showingAddExercise = false
    @State private var workoutName: String
    
    init(viewModel: ActiveWorkoutViewModel) {
        self.viewModel = viewModel
        _workoutName = State(initialValue: viewModel.activeWorkout?.name ?? "")
    }
    
    var body: some View {
        Group {
            if let workout = viewModel.activeWorkout {
                workoutContent(workout: workout)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            workoutName = viewModel.activeWorkout?.name ?? ""
        }
    }
    
    private func workoutContent(workout: Workout) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timer
                timerView
                
                // Workout name
                TextField("Workout Name", text: $workoutName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onChange(of: workoutName) { oldValue, newValue in
                        workout.name = newValue.isEmpty ? nil : newValue
                        try? modelContext.save()
                    }
                
                // Exercises
                if let entries = workout.entries?.sorted(by: { $0.order < $1.order }), !entries.isEmpty {
                    ForEach(entries) { entry in
                        ExerciseSectionView(
                            entry: entry,
                            viewModel: viewModel
                        )
                    }
                } else {
                    Text("No exercises yet")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                
                // Add Exercise button
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Finish Workout button
                Button {
                    viewModel.finishWorkout()
                } label: {
                    Text("Finish Workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingCancelAlert = true
                } label: {
                    Text("Cancel")
                }
            }
        }
        .alert("Cancel Workout", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                viewModel.cancelWorkout()
            }
        } message: {
            Text("Are you sure you want to discard this workout? All progress will be lost.")
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutSheet(viewModel: viewModel)
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 4) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(formatElapsedTime(viewModel.elapsedTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ExerciseSectionView: View {
    let entry: WorkoutEntry
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(entry.exercise?.name ?? "Unknown Exercise")
                .font(.headline)
                .padding(.horizontal, 4)
            
            // Sets
            let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
            ForEach(sets) { set in
                SetRowView(
                    set: set,
                    onUpdate: { updatedSet, reps, weight, isCompleted in
                        viewModel.updateSet(
                            in: entry,
                            set: updatedSet,
                            reps: reps,
                            weight: weight,
                            isCompleted: isCompleted
                        )
                    },
                    onDelete: {
                        viewModel.removeSet(from: entry, set: set)
                    }
                )
            }
            
            // Add Set button
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
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(viewModel: ActiveWorkoutViewModel())
            .modelContainer(for: [Workout.self, WorkoutEntry.self, Exercise.self], inMemory: true)
    }
}
