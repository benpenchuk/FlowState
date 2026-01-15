//
//  Exercise.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case strength
    case cardio
}

enum Equipment: String, Codable, CaseIterable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case resistanceBand
    case ezBar
    case trapBar
    case smithMachine
    case pullupBar
    case dipBars
    case bench
    case inclineBench
    case declineBench
    // Cardio equipment
    case treadmill
    case bike
    case rowingMachine
    case elliptical
    case stairClimber
    case jumpRope
    case none
}

struct ExerciseInstructions: Codable {
    var setup: String
    var execution: String
    var tips: String
    
    init(setup: String = "", execution: String = "", tips: String = "") {
        self.setup = setup
        self.execution = execution
        self.tips = tips
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var exerciseType: ExerciseType
    var category: String // "Chest", "Back", "Running", etc.
    var equipment: [Equipment] // Array of equipment options
    var primaryMuscles: [String] // For strength exercises
    var secondaryMuscles: [String] // For strength exercises
    var instructions: ExerciseInstructions // Structured instructions
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateExercises: [TemplateExercise]?
    
    @Relationship(deleteRule: .nullify, inverse: \WorkoutEntry.exercise)
    var workoutEntries: [WorkoutEntry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        exerciseType: ExerciseType,
        category: String,
        equipment: [Equipment] = [],
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        instructions: ExerciseInstructions = ExerciseInstructions(),
        isCustom: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.category = category
        self.equipment = equipment
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}
