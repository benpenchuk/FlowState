//
//  SetRecord.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation

struct SetRecord: Codable, Identifiable {
    var id: UUID
    var setNumber: Int
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var distance: Double?
    var equipment: String? // Optional: which equipment was used this set
    var isCompleted: Bool
    
    init(id: UUID = UUID(), setNumber: Int, reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, distance: Double? = nil, equipment: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.equipment = equipment
        self.isCompleted = isCompleted
    }
}
