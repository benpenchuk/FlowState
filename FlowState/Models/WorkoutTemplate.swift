//
//  WorkoutTemplate.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]?
    
    init(id: UUID = UUID(), name: String, exercises: [TemplateExercise] = [], createdAt: Date = Date(), lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
