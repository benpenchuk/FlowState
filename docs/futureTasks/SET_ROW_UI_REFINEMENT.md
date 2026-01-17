# Set Row UI Refinement & Future Improvements

**Date:** January 17, 2026
**Status:** Completed Phase 1 (Simplification)

## Recap of Recent Changes

### 1. Exercise Section Headers
- **Change:** Moved "WEIGHT" and "REPS" labels from individual rows into a single header at the top of each exercise card.
- **Impact:** Drastically reduced visual noise and redundancy. Each set now focuses purely on the numbers.

### 2. Single-Row Set Layout
- **Change:** Reworked `SetRowView` to align on a single horizontal baseline. Removed all sub-labeling ("lbs", "reps") and "Last session" sub-text from the input boxes.
- **Impact:** The UI feels more spacious and modern. Row heights are consistent across all sets.

### 3. Responsive Column Alignment
- **Change:** Used `maxWidth: .infinity` for the Weight and Reps columns in `SetRowView`.
- **Impact:** Columns now align perfectly across different rows and adapt to different screen sizes.

### 4. Rest Timer Reset Pulse
- **Change:** Added a visual "pop" (scale + color flash) to the Rest Timer pill (both compact and full versions) when a set is completed.
- **Impact:** Provides clear visual confirmation that the timer has reset without requiring the user to look directly at the timer.

---

## Improvements to Revisit

### 1. Re-integrating "Last Session" Data
We removed the "Last session" text because it was cramping the UI. However, this is critical information for progressive overload.
- **Idea:** Explore "Ghost" values that only appear in the specific field currently being edited.
- **Idea:** Add a "Previous" tab or a long-press gesture on the input box to peek at the previous session's weight/reps.
- **Idea:** Re-introduce a subtle summary line if we can find a placement that doesn't break the single-row layout.

### 2. Drag Handle & Reordering UX
The drag handles are currently on the far left.
- **Task:** Review the ergonomics of reordering sets.
- **Idea:** Consider if the handle should be larger or if we should support long-press-to-drag anywhere on the row.
- **Task:** Fix the "Drop Target" visual feedback to be more consistent with the new simplified row style.

### 3. Keypad Integration
- **Idea:** Ensure the custom keypad doesn't overlap the row being edited, or implement an "Auto-scroll to active row" when the keypad is open to keep the user's focus clear.

### 4. Visual Polish for Completion
- **Idea:** Experiment with a more "satisfied" completion state (e.g., a subtle green glow or a different checkmark animation) to celebrate finishing a heavy set.
