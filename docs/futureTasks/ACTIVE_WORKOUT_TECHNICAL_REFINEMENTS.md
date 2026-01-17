# Active Workout Technical Refinements

This document outlines technical improvements for the `ActiveWorkoutFullScreenView` and its associated ViewModels to improve performance, maintainability, and architectural consistency.

## 1. State Management & Source of Truth
- **Manager-ViewModel Synchronization**: Currently, both `WorkoutStateManager` and `ActiveWorkoutViewModel` track the `activeWorkout`. This leads to redundant synchronization logic in the View's `onAppear` and `onChange` modifiers.
- **Refinement**: Let `ActiveWorkoutViewModel` observe `WorkoutStateManager` directly or pass the `Workout` object once to the ViewModel. Ideally, the ViewModel should be the primary interface for the View, delegating to the Manager as needed.

## 2. Performance Optimizations
- **Memoize Computed Properties**: Properties like `exerciseProgress` and `countCompletedSets` iterate through the entire workout structure (entries and sets).
- **Refinement**: Calculate these metrics in the ViewModel only when the underlying data changes (e.g., when a set is completed or deleted) and publish them as `@Published` properties. This avoids heavy iteration on every view body re-computation.

## 3. UI Configuration & Constants
- **Magic Numbers**: The scroll threshold for transitioning headers (`scrollOffset < 50`) is currently hardcoded in the View.
- **Refinement**: Move these thresholds and other layout-specific constants (like animation durations or specialized opacities) into `ActiveWorkoutLayout.swift`.

## 4. Initialization Flow
- **ModelContext Handling**: `ActiveWorkoutViewModel` is initialized in the View's `init`, but its `modelContext` is set later in `onAppear`.
- **Refinement**: Ensure the ViewModel's internal logic is resilient to a `nil` context during early lifecycle phases, or consider an architecture where the context is injected via the environment more robustly.

## 5. Event Handling
- **Rest Timer Logic**: The logic for starting the rest timer and triggering pulse animations is currently handled within the `ExerciseSectionView` closure.
- **Refinement**: Move this coordination logic into the `ActiveWorkoutViewModel` to keep the View focused purely on rendering.
