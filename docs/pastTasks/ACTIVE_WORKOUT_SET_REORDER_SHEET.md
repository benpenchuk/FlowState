## Active Workout — Set Reordering (Sheet-Based)

### Summary
- **Problem**: Inline drag/drop reordering inside the set list created awkward visuals (shading/target outlines) and generally felt “busy” in the middle of logging.
- **Change**: Moved set reordering to a dedicated **“Reorder Sets”** sheet per exercise, using native list reorder handles.
- **Result**: Main logging UI stays clean; reordering is still available when needed.

### What shipped
- **New sheet**: `FlowState/Views/ReorderSetsSheet.swift`
  - Presented from the exercise `…` menu as **Reorder Sets** (only when `sets.count > 1`).
  - Uses `List` + `.onMove` with `EditMode.active` so the system reorder UI is consistent and reliable.
  - Shows a compact row summary (set number, weight/reps, label dot, completion state).

- **Persistence by ID**: `ActiveWorkoutViewModel.applySetOrder(in:orderedSetIds:)`
  - Reorders by stable `SetRecord.id` and then renumbers `setNumber` to 1…N.
  - Avoids index drift and keeps storage (`WorkoutEntry.setsData`) consistent.

- **Removed inline reorder system**
  - Removed `.onDrag` / `.onDrop` logic and its drag visuals from `FlowState/Views/ExerciseSectionView.swift`.
  - Removed the misleading drag-handle affordance from `FlowState/Views/SetRowView.swift`.

### UX notes / why this is “good enough” for now
- The sheet adds one extra tap, but it’s **intentional**: reordering is a secondary action and shouldn’t compete with logging inputs.
- The native reorder handles are familiar and don’t require custom drop-target highlighting.

### Follow-ups (tracked separately)
- There is likely a **smoother** UX we can do later (fewer steps, clearer entry point, better context). See the future task doc:
  - `docs/futureTasks/ACTIVE_WORKOUT_SET_REORDER_IMPROVEMENTS.md`

