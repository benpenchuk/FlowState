## Active Workout — Set Reordering Improvements (UX)

### Context
We moved set reordering to a dedicated sheet (`ReorderSetsSheet`) to remove awkward inline drag/drop visuals and reduce clutter in the logging UI. This is solid for now, but there’s room to make it feel **faster** and **more discoverable**.

### Goals
- **Speed**: reduce taps + reduce context switching.
- **Clarity**: users should immediately understand how to reorder and what it affects.
- **Safety**: avoid accidental reorders while logging.
- **Feedback**: clear confirmation that the order changed.

### Current pain points (likely)
- Reordering is “hidden” behind the `…` menu.
- Opening a sheet is a context switch that can feel heavy for a quick reorder.
- Row content is informational only; it may not be obvious this changes the live set order (and renumbers).

### Options (from least to most “inline”)

#### Option A — Keep the sheet, but make it smoother (recommended next step)
- **Entry point**:
  - Add a small “Reorder” button near the set headers (only when 2+ sets), or
  - Promote “Reorder Sets” higher in the menu (keep `…` as fallback).
- **Sheet UX**:
  - Show a short hint at top: “Drag handles to reorder. Set numbers will update.”
  - Add subtle haptic on drop (on move end) for confirmation.
  - Add a brief toast/snackbar after closing: “Set order updated.”
- **Row display**:
  - Show “New #” explicitly (the list index), not the old `setNumber`.
  - Include more context: label name text (optional), last-session hint (optional).

#### Option B — “Reorder Mode” inside the exercise card (no sheet)
- Add a **toggle** (e.g., “Reorder”) that switches the set list into an “edit” state:
  - disables weight/reps editing while active,
  - shows reorder handles on each set row,
  - uses a simpler row layout.
- Pros: fewer taps, more immediate.
- Cons: more UI complexity; risk of confusion if editing vs reorder states aren’t very clear.

#### Option C — Fast non-drag controls (accessibility-friendly)
- Swipe actions: **Move Up** / **Move Down**.
- Inline buttons shown only in “Reorder Mode”.
- Pros: works well with one-handed use and VoiceOver.
- Cons: slower for large moves; more taps.

### Recommended plan

#### Phase 1 (quick UX wins)
- Improve entry point discoverability (button near headers or promoted menu item).
- Improve sheet copy + visuals:
  - explicit “New Set #” display,
  - short hint text,
  - light haptic on reorder.

#### Phase 2 (reduce context switch)
- Prototype “Reorder Mode” inside the exercise card:
  - disable logging inputs in reorder mode,
  - show reorder handles,
  - provide a clear “Done” button.
- Compare against sheet in real usage (speed vs confusion).

#### Phase 3 (polish + accessibility)
- Add swipe “Move Up/Down” as an alternative to drag.
- Ensure VoiceOver announces reordering changes clearly.

### Implementation notes
- Persistence should remain **stable-by-ID** (`SetRecord.id`), then renumber `setNumber` to 1…N.
- Any “inline reorder mode” should be careful to avoid fighting with:
  - keyboard focus,
  - custom numpad sheet,
  - scroll/gesture conflicts.

