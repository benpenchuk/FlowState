//
//  UserProfile.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData

enum Units: String, Codable, CaseIterable {
    case lbs
    case kg
}

enum AppearanceMode: String, Codable, CaseIterable {
    case dark
    case light
    case system
}

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var createdAt: Date
    var preferredUnits: String // Store as String (Units.rawValue)
    var defaultRestTime: Int // seconds
    var appearanceMode: String // Store as String (AppearanceMode.rawValue)
    
    init(
        id: UUID = UUID(),
        name: String = "Athlete",
        createdAt: Date = Date(),
        preferredUnits: Units = .lbs,
        defaultRestTime: Int = 90,
        appearanceMode: AppearanceMode = .system
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.preferredUnits = preferredUnits.rawValue
        self.defaultRestTime = defaultRestTime
        self.appearanceMode = appearanceMode.rawValue
    }
    
    // Computed properties for easier access
    var units: Units {
        get {
            Units(rawValue: preferredUnits) ?? .lbs
        }
        set {
            preferredUnits = newValue.rawValue
        }
    }
    
    var appearance: AppearanceMode {
        get {
            AppearanceMode(rawValue: appearanceMode) ?? .system
        }
        set {
            appearanceMode = newValue.rawValue
        }
    }
}
