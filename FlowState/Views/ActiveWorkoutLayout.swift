//
//  ActiveWorkoutLayout.swift
//  FlowState
//
//  Centralized spacing/sizing for Active Workout UI.
//  Keeping these in one place prevents conflicting nested padding and
//  reduces the chance of horizontal clipping on smaller devices.
//

import SwiftUI

enum ActiveWorkoutLayout {
    /// Padding around the scroll content body.
    static let contentPadding: CGFloat = 16

    /// Outer padding inside an exercise card.
    static let exerciseCardPadding: CGFloat = 16

    /// Spacing between major sections inside the workout body.
    static let workoutSectionSpacing: CGFloat = 20

    /// Standard corner radius used by exercise cards.
    static let exerciseCardCornerRadius: CGFloat = 16

    /// Scroll offset threshold for switching to compact header
    static let headerTransitionThreshold: CGFloat = 40
}

