//
//  ExerciseLibraryViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText: String = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadAllExercises()
        seedDefaultExercisesIfNeeded()
    }
    
    func loadAllExercises() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            let fetchedExercises = try modelContext.fetch(descriptor)
            exercises = fetchedExercises.sorted { exercise1, exercise2 in
                if exercise1.category.rawValue == exercise2.category.rawValue {
                    return exercise1.name < exercise2.name
                }
                return exercise1.category.rawValue < exercise2.category.rawValue
            }
        } catch {
            print("Error loading exercises: \(error)")
            exercises = []
        }
    }
    
    func addCustomExercise(name: String, category: ExerciseCategory) {
        guard let modelContext = modelContext else { return }
        
        let exercise = Exercise(name: name, category: category, isCustom: true)
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error adding exercise: \(error)")
        }
    }
    
    func deleteCustomExercise(_ exercise: Exercise) {
        guard let modelContext = modelContext,
              exercise.isCustom else { return }
        
        modelContext.delete(exercise)
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }
    
    private func seedDefaultExercisesIfNeeded() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        guard count == 0 else { return }
        
        let defaultExercises: [(String, ExerciseCategory)] = [
            // Chest
            ("Bench Press", .chest),
            ("Incline Bench Press", .chest),
            ("Dumbbell Flyes", .chest),
            ("Push-Ups", .chest),
            ("Cable Crossover", .chest),
            
            // Back
            ("Deadlift", .back),
            ("Pull-Ups", .back),
            ("Barbell Rows", .back),
            ("Lat Pulldown", .back),
            ("Seated Cable Row", .back),
            
            // Shoulders
            ("Overhead Press", .shoulders),
            ("Lateral Raises", .shoulders),
            ("Front Raises", .shoulders),
            ("Face Pulls", .shoulders),
            ("Arnold Press", .shoulders),
            
            // Arms
            ("Bicep Curls", .arms),
            ("Hammer Curls", .arms),
            ("Tricep Pushdown", .arms),
            ("Tricep Dips", .arms),
            ("Skull Crushers", .arms),
            
            // Legs
            ("Squat", .legs),
            ("Leg Press", .legs),
            ("Lunges", .legs),
            ("Leg Curl", .legs),
            ("Leg Extension", .legs),
            ("Calf Raises", .legs),
            
            // Core
            ("Plank", .core),
            ("Crunches", .core),
            ("Russian Twists", .core),
            ("Leg Raises", .core),
            ("Ab Rollout", .core),
            
            // Cardio
            ("Running", .cardio),
            ("Walking", .cardio),
            ("Cycling", .cardio),
            ("Rowing", .cardio),
            ("Stair Climber", .cardio),
            ("Jump Rope", .cardio),
        ]
        
        for (name, category) in defaultExercises {
            let exercise = Exercise(name: name, category: category, isCustom: false)
            modelContext.insert(exercise)
        }
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error seeding exercises: \(error)")
        }
    }
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var exercisesByCategory: [ExerciseCategory: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.category }
    }
    
    var sortedCategories: [ExerciseCategory] {
        exercisesByCategory.keys.sorted { $0.rawValue < $1.rawValue }
    }
}
