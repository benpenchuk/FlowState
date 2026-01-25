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

    /// Header collapse threshold when scrolling down (hysteresis).
    static let headerCollapseThreshold: CGFloat = 60

    /// Header expand threshold when scrolling back up (hysteresis).
    static let headerExpandThreshold: CGFloat = 40

    /// Extra bottom space inside the scroll content to avoid "hard bottom" interactions.
    static let bottomScrollBuffer: CGFloat = 32
}

