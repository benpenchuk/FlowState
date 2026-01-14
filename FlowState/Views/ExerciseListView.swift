//
//  ExerciseListView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var showingAddExercise = false
    
    var body: some View {
        List {
            ForEach(viewModel.sortedCategories, id: \.self) { category in
                if let exercises = viewModel.exercisesByCategory[category], !exercises.isEmpty {
                    Section {
                        let defaultExercises = exercises.filter { !$0.isCustom }
                        let customExercises = exercises.filter { $0.isCustom }
                        
                        ForEach(defaultExercises) { exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                        
                        ForEach(customExercises) { exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                        .onDelete { indexSet in
                            deleteExercises(at: indexSet, in: customExercises)
                        }
                    } header: {
                        Text(category.rawValue)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search exercises")
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    private func deleteExercises(at offsets: IndexSet, in exercises: [Exercise]) {
        for index in offsets {
            let exercise = exercises[index]
            viewModel.deleteCustomExercise(exercise)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            Text(exercise.name)
            
            Spacer()
            
            if exercise.isCustom {
                Label("Custom", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
            .modelContainer(for: Exercise.self, inMemory: true)
    }
}
