# Active Workout — Set Reordering Improvements (UX)

**Status:** Partially Completed - Core functionality implemented, UX improvements pending

## Context
We moved set reordering to a dedicated sheet (`ReorderSetsSheet`) to remove awkward inline drag/drop visuals and reduce clutter in the logging UI. The core functionality is working, but there's room to make it feel **faster** and **more discoverable**.

## ✅ What's Been Completed
- **Core reordering functionality**: `ReorderSetsSheet` exists and works (`FlowState/Views/ReorderSetsSheet.swift`)
- **Entry point**: Available via "Reorder Sets" option in exercise section menu (`ExerciseSectionView.swift`, line 132-134)
- **Drag-and-drop**: Functional drag handles with reordering via `.onMove`
- **Persistence**: Set order updates correctly via `viewModel.applySetOrder()`
- **Set renumbering**: Sets are automatically renumbered after reordering
- **New Set # display**: Sheet shows "Set {displaySetNumber}" which reflects the new order (line 67)
- **Footer hint text**: Sheet includes footer explaining drag functionality (line 39)
- **Done button**: Clear dismissal button in navigation bar (line 48)

## Goals
- **Speed**: reduce taps + reduce context switching.
- **Clarity**: users should immediately understand how to reorder and what it affects.
- **Safety**: avoid accidental reorders while logging.
- **Feedback**: clear confirmation that the order changed.

## ⚠️ Current Pain Points (Still Need Improvement)
- **Entry point discoverability**: Reordering is "hidden" behind the `…` menu (not easily discoverable)
- **Context switching**: Opening a sheet is a context switch that can feel heavy for a quick reorder
- **No haptic feedback**: Missing haptic feedback on reorder completion for confirmation
- **No toast notification**: No visual confirmation when sheet is dismissed that order was updated
- **Entry point visibility**: Could benefit from a more prominent button when 2+ sets exist

## Options (from least to most "inline")

### Option A — Keep the sheet, but make it smoother (recommended next step)
- **Entry point** (⚠️ NOT DONE):
  - Add a small "Reorder" button near the set headers (only when 2+ sets), or
  - Promote "Reorder Sets" higher in the menu (keep `…` as fallback).
- **Sheet UX**:
  - ✅ Show a short hint at top: "Drag handles to reorder. Set numbers will update." (Footer text exists, line 39)
  - ⚠️ Add subtle haptic on drop (on move end) for confirmation. (NOT IMPLEMENTED)
  - ⚠️ Add a brief toast/snackbar after closing: "Set order updated." (NOT IMPLEMENTED)
- **Row display**:
  - ✅ Show "New #" explicitly (the list index), not the old `setNumber`. (ALREADY DONE - line 67 shows `displaySetNumber`)
  - ✅ Include more context: label name text (optional), last-session hint (optional). (Label shown if not .none, line 77-82)

### Option B — "Reorder Mode" inside the exercise card (no sheet)
- Add a **toggle** (e.g., "Reorder") that switches the set list into an "edit" state:
  - disables weight/reps editing while active,
  - shows reorder handles on each set row,
  - uses a simpler row layout.
- Pros: fewer taps, more immediate.
- Cons: more UI complexity; risk of confusion if editing vs reorder states aren't very clear.

### Option C — Fast non-drag controls (accessibility-friendly)
- Swipe actions: **Move Up** / **Move Down**.
- Inline buttons shown only in "Reorder Mode".
- Pros: works well with one-handed use and VoiceOver.
- Cons: slower for large moves; more taps.

## Recommended plan

### Phase 1 (quick UX wins) - ⚠️ PARTIALLY DONE
- ⚠️ Improve entry point discoverability (button near headers or promoted menu item) - NOT DONE
- Improve sheet copy + visuals:
  - ✅ explicit "New Set #" display - ALREADY DONE (shows displaySetNumber)
  - ✅ short hint text - ALREADY DONE (footer text exists)
  - ⚠️ light haptic on reorder - NOT DONE
  - ⚠️ toast notification on dismiss - NOT DONE

### Phase 2 (reduce context switch) - ⚠️ NOT STARTED
- Prototype "Reorder Mode" inside the exercise card:
  - disable logging inputs in reorder mode,
  - show reorder handles,
  - provide a clear "Done" button.
- Compare against sheet in real usage (speed vs confusion).

### Phase 3 (polish + accessibility) - ⚠️ NOT STARTED
- Add swipe "Move Up/Down" as an alternative to drag.
- Ensure VoiceOver announces reordering changes clearly.
- Add toast notification when sheet is dismissed: "Set order updated."

## Implementation notes
- Persistence should remain **stable-by-ID** (`SetRecord.id`), then renumber `setNumber` to 1…N.
- Any "inline reorder mode" should be careful to avoid fighting with:
  - keyboard focus,
  - custom numpad sheet,
  - scroll/gesture conflicts.
