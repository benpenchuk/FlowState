//
//  ExerciseFilters.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/25/26.
//

import Foundation

enum MuscleGroupFilter: String, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .chest: return "heart.fill"
        case .back: return "figure.strengthtraining.traditional"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .arms: return "hand.raised.fill"
        case .core: return "circle.grid.cross.fill"
        }
    }
}

enum EquipmentChip: String, CaseIterable, Identifiable, Hashable {
    case barbell
    case dumbbell
    case cable
    case bodyweight
    case machine
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .machine: return "Machine"
        }
    }
    
    var symbolName: String {
        switch self {
        case .barbell: return "scalemass.fill"
        case .dumbbell: return "dumbbell.fill"
        case .cable: return "cable.connector"
        case .bodyweight: return "figure.walk"
        case .machine: return "gearshape.2.fill"
        }
    }
    
    var equipment: Equipment {
        switch self {
        case .barbell: return .barbell
        case .dumbbell: return .dumbbell
        case .cable: return .cable
        case .bodyweight: return .bodyweight
        case .machine: return .machine
        }
    }
}

