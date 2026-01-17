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

struct ExerciseInstructions: Codable, Sendable {
    var setup: String
    var execution: String
    var tips: String
    
    nonisolated init(setup: String = "", execution: String = "", tips: String = "") {
        self.setup = setup
        self.execution = execution
        self.tips = tips
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setup = try container.decode(String.self, forKey: .setup)
        execution = try container.decode(String.self, forKey: .execution)
        tips = try container.decode(String.self, forKey: .tips)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(setup, forKey: .setup)
        try container.encode(execution, forKey: .execution)
        try container.encode(tips, forKey: .tips)
    }
    
    enum CodingKeys: String, CodingKey {
        case setup, execution, tips
    }
}

@Model
nonisolated final class Exercise {
    var id: UUID
    var name: String
    var exerciseType: ExerciseType
    var category: String // "Chest", "Back", "Running", etc.
    var equipment: [Equipment] // Array of equipment options
    var primaryMuscles: [String] // For strength exercises
    var secondaryMuscles: [String] // For strength exercises
    var instructionsData: Data? // Stores ExerciseInstructions as JSON
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
        instructions: ExerciseInstructions? = nil,
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
        // Create default instructions in nonisolated context
        let finalInstructions = instructions ?? ExerciseInstructions(setup: "", execution: "", tips: "")
        // Encode in nonisolated context by explicitly creating encoder
        let encoder = JSONEncoder()
        self.instructionsData = try? encoder.encode(finalInstructions)
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
    
    // Helper method to get instructions as ExerciseInstructions
    nonisolated func getInstructions() -> ExerciseInstructions {
        guard let data = instructionsData else {
            return ExerciseInstructions(setup: "", execution: "", tips: "")
        }
        // Decode in nonisolated context by explicitly creating decoder
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(ExerciseInstructions.self, from: data) else {
            return ExerciseInstructions(setup: "", execution: "", tips: "")
        }
        return decoded
    }
    
    // Helper method to set instructions
    nonisolated func setInstructions(_ instructions: ExerciseInstructions) {
        let encoder = JSONEncoder()
        instructionsData = try? encoder.encode(instructions)
    }
}
