//
//  Exercise.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case other = "Other"
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var isCustom: Bool
    var notes: String?
    
    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateExercises: [TemplateExercise]?
    
    @Relationship(deleteRule: .nullify, inverse: \WorkoutEntry.exercise)
    var workoutEntries: [WorkoutEntry]?
    
    init(id: UUID = UUID(), name: String, category: ExerciseCategory, isCustom: Bool = false, notes: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.isCustom = isCustom
        self.notes = notes
    }
}
