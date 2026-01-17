//
//  SetRecord.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation

enum SetLabel: String, Codable, CaseIterable {
    case none = "None"
    case warmup = "Warmup"
    case failure = "Failure"
    case dropSet = "Drop Set"
    case prAttempt = "PR Attempt"
}

struct SetRecord: Codable, Identifiable {
    var id: UUID
    var setNumber: Int
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var distance: Double?
    var equipment: String? // Optional: which equipment was used this set
    var isCompleted: Bool
    var completedAt: Date? // When this set was marked complete
    var label: SetLabel // Label for the set (Warmup, Failure, etc.)
    
    init(id: UUID = UUID(), setNumber: Int, reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, distance: Double? = nil, equipment: String? = nil, isCompleted: Bool = false, completedAt: Date? = nil, label: SetLabel = .none) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.equipment = equipment
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.label = label
    }
}
