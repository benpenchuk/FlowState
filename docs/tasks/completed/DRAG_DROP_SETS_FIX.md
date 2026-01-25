# Set Reordering (Active Workout) — Design Notes

## Summary

Set reordering in the Active Workout UI moved from **inline drag/drop inside the set list** to a **dedicated “Reorder Sets” sheet** per exercise. This keeps the main logging UI calm and avoids odd-looking inline shading/targets while still supporting quick reordering via native list handles.

## Current UX

- In the Active Workout exercise card, open the `…` menu and tap **Reorder Sets** (only shown when there are 2+ sets).
- A sheet opens with a `List` in reorder mode.
- Drag the reorder handles to rearrange sets.
- Ordering is persisted immediately.

## Implementation

### Key files

- **`FlowState/Views/ExerciseSectionView.swift`**
  - Adds the “Reorder Sets” menu item and presents the sheet.
  - Removes the old inline drag/drop reordering system and its visuals.

- **`FlowState/Views/ReorderSetsSheet.swift`**
  - Displays sets in a `List` with `EditMode.active` and `.onMove`.

- **`FlowState/ViewModels/ActiveWorkoutViewModel.swift`**
  - `applySetOrder(in:orderedSetIds:)` persists a stable-by-ID ordering and renumbers `setNumber` 1...N.

### Why this approach

- **Predictable visuals**: no “darkened”/shaded rows or drop-target outlines competing with the logging UI.
- **Native interaction**: `List` reordering behaves consistently across devices and iOS versions.
- **Stable persistence**: ordering is applied by `SetRecord.id`, then renumbered, avoiding index drift.

