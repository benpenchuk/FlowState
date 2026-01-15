//
//  PersonalRecord.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID
    var weight: Double
    var reps: Int
    var achievedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var exercise: Exercise?
    
    @Relationship(deleteRule: .nullify)
    var workout: Workout?
    
    init(id: UUID = UUID(), exercise: Exercise, weight: Double, reps: Int, achievedAt: Date = Date(), workout: Workout? = nil) {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.achievedAt = achievedAt
        self.workout = workout
    }
}
