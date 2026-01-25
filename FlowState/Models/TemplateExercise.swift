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
    var defaultLabels: Data? // Stores [SetLabel] as JSON
    
    @Relationship
    var exercise: Exercise?
    
    @Relationship
    var template: WorkoutTemplate?
    
    init(id: UUID = UUID(), exercise: Exercise, order: Int, defaultSets: Int, defaultReps: Int, defaultWeight: Double? = nil, defaultLabels: [SetLabel]? = nil) {
        self.id = id
        self.exercise = exercise
        self.order = order
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.defaultLabels = try? JSONEncoder().encode(defaultLabels ?? [])
    }
    
    // Helper method to get labels as [SetLabel]
    func getDefaultLabels() -> [SetLabel] {
        guard let data = defaultLabels,
              let decoded = try? JSONDecoder().decode([SetLabel].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Helper method to set labels
    func setDefaultLabels(_ labels: [SetLabel]) {
        defaultLabels = try? JSONEncoder().encode(labels)
    }
}
