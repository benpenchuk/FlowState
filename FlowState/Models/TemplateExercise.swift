//
//  TemplateExercise.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID
    var order: Int
    var defaultSets: Int
    var defaultReps: Int
    var defaultWeight: Double?
    
    @Relationship
    var exercise: Exercise?
    
    @Relationship
    var template: WorkoutTemplate?
    
    init(id: UUID = UUID(), exercise: Exercise, order: Int, defaultSets: Int, defaultReps: Int, defaultWeight: Double? = nil) {
        self.id = id
        self.exercise = exercise
        self.order = order
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
    }
}
