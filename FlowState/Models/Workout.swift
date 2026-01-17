//
//  Workout.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var name: String?
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    var effortRating: Int? // 1-10 scale, optional
    var totalRestTime: TimeInterval? // Sum of all rest periods
    var totalVolume: Double? // Total volume in lbs (weight × reps for all completed sets)
    
    @Relationship(deleteRule: .cascade)
    var entries: [WorkoutEntry]?
    
    init(id: UUID = UUID(), name: String? = nil, startedAt: Date = Date(), completedAt: Date? = nil, notes: String? = nil, effortRating: Int? = nil, totalRestTime: TimeInterval? = nil, totalVolume: Double? = nil, entries: [WorkoutEntry] = []) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.effortRating = effortRating
        self.totalRestTime = totalRestTime
        self.totalVolume = totalVolume
        self.entries = entries
    }
}
