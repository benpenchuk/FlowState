# Template Cards & Loading States Update

## Overview
This task focused on improving the visual density and utility of workout template cards on the Home screen and implementing a consistent loading experience across the entire application using skeleton views.

## 1. Enhanced Template Cards
The `TemplateCardView` was transformed from a minimal card to a high-utility preview component.

- **Exercise Preview**: Shows the first 3 exercises with bullet points.
- **Sets/Reps Info**: Integrated volume data (e.g., `3×10`) aligned to the right for quick scanning.
- **Usage History**: Added a "Last used" indicator with a custom short-form relative date formatter (e.g., `45m ago`, `2h ago`).
- **Identity Labels**: Re-added the dumbbell icon and exercise count for clear routine identification.
- **Play Indicator**: Added a `play.circle.fill` icon to signal tappability and primary action.
- **Context Menus**: Added a long-press menu for Edit, Duplicate, and Delete actions.
- **Duplicate Template**: Implemented backend logic to clone templates and their associated exercises.

## 2. Global Loading States
Implemented a professional loading experience to replace standard spinners.

- **ViewModels**: Added `@Published var isLoading` to `TemplateViewModel`, `HistoryViewModel`, `ExerciseLibraryViewModel`, `ProfileViewModel`, and `ProgressViewModel`.
- **Skeleton Directory**: Created `FlowState/Views/Skeletons/` to house reusable skeleton components.
- **Components**:
    - `SkeletonTemplateCard`: Matches the 150pt HomeView card layout.
    - `SkeletonPRCard`: Used for personal record lists.
    - `SkeletonExerciseRow`: Used for exercise library lists.
    - `SkeletonWorkoutHistoryCard`: Used for history rows.
    - `SkeletonStatsCard`: Used for metrics on Home and Profile screens.
- **Implementation**: Integrated these skeletons into `HomeView`, `HistoryView`, `ExerciseListView`, `ProfileView`, and `ExerciseDetailView` using SwiftUI's `.redacted(reason: .placeholder)` for native shimmer effects.

## 3. UI Refinement
Refined the final card layout based on user feedback to find the "Goldilocks" balance of information.

- **Height Optimization**: Stabilized at `150pt` for a clean, non-crammed feel.
- **Metric Pruning**: Removed the `lastVolume` metric to reduce vertical clutter and improve breathing room.
- **Contrast Improvements**: Adjusted foreground styles to `.secondary` and `.tertiary` to establish a clear visual hierarchy.

## Impact
- **Increased Engagement**: Users can now see exactly what is in a template before starting it.
- **Professional Feel**: The app no longer "flashes" empty states during data fetch; instead, it shows smooth, theme-aware shimmer placeholders.
- **Improved Management**: Templates can now be managed directly from the Home screen via context menus.
