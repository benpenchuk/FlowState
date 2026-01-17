//
//  WorkoutEntry.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var id: UUID
    var order: Int
    var setsData: Data? // Stores [SetRecord] as JSON
    var notes: String? // Per-exercise notes during workout
    
    @Relationship
    var exercise: Exercise?
    
    @Relationship(inverse: \Workout.entries)
    var workout: Workout?
    
    init(id: UUID = UUID(), exercise: Exercise, order: Int, sets: [SetRecord] = [], workout: Workout? = nil, notes: String? = nil) {
        self.id = id
        self.exercise = exercise
        self.order = order
        self.workout = workout
        self.setsData = try? JSONEncoder().encode(sets)
        self.notes = notes
    }
    
    // Helper method to get sets as [SetRecord]
    func getSets() -> [SetRecord] {
        guard let data = setsData,
              let decoded = try? JSONDecoder().decode([SetRecord].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Helper method to set sets
    func setSets(_ sets: [SetRecord]) {
        setsData = try? JSONEncoder().encode(sets)
    }
}
