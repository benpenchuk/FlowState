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
    
    @Relationship(deleteRule: .cascade)
    var entries: [WorkoutEntry]?
    
    init(id: UUID = UUID(), name: String? = nil, startedAt: Date = Date(), completedAt: Date? = nil, notes: String? = nil, entries: [WorkoutEntry] = []) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.entries = entries
    }
}
