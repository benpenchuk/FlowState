# Set Labels Discoverability (Warmup / Drop Set / etc.)

## Problem
Users can’t figure out how to mark a set as **Warmup**, **Drop Set**, etc., even though the capability exists.

### Current behavior (as of Jan 2026)
- Set labels are stored on `SetRecord.label` (`FlowState/Models/SetRecord.swift`).
- Label selection UI exists via `LabelPickerSheet` (`FlowState/Views/LabelPickerSheet.swift`).
- Persistence exists via `ActiveWorkoutViewModel.updateSetLabel(...)` (`FlowState/ViewModels/ActiveWorkoutViewModel.swift`).
- **But** the primary UX to access it is a **long-press** on a tiny label indicator in `SetRowView` (`FlowState/Views/SetRowView.swift`).
  - When the label is `.none`, the indicator is `Color.clear` (invisible), making the gesture effectively undiscoverable.

## Goal
Make set labeling **obvious and fast** during an active workout.

## Proposed UX options
Pick one primary entry point (and optionally add a secondary shortcut).

### Option A (recommended): Visible, tappable label button
- Replace the invisible/long-press-only target with a visible control:
  - If label is `.none`: show a small `tag` icon/button.
  - If label is set: show a small colored badge (e.g., `W`, `D`, `F`, `PR`).
- Tap opens `LabelPickerSheet`.

**Pros**
- Discoverable.
- Works great one-handed.
- No new screens required (reuse `LabelPickerSheet`).

**Cons**
- Slightly more visual complexity in each set row.

### Option B: Context menu on set row (secondary)
- Add `.contextMenu` on the label control or the entire set row:
  - Items: None, Warmup, Failure, Drop Set, PR Attempt
  - Selecting updates immediately via `onLabelUpdate`.

**Pros**
- Very fast for power users.

**Cons**
- Still not fully discoverable for many users.

### Option C: Swipe action
- Add a trailing (or leading) swipe action like “Label” that opens the picker.

**Pros**
- Discoverable (users already swipe for actions).

**Cons**
- Conflicts with any existing swipe-to-delete patterns depending on the row context.

## Acceptance criteria
- **Discoverability**: A user can find labeling without being told about a hidden gesture.
- **Speed**: Change label in \(\le 2\) taps from the set row.
- **Works when label is None**: There is still an obvious affordance to add a label.
- **Persists**: The label remains after navigation and after app relaunch (SwiftData save).
- **Accessibility**: VoiceOver announces current label and hints that it’s editable.

## Implementation notes
- Primary file to change: `FlowState/Views/SetRowView.swift`
  - Add a visible label control (Option A), and wire it to the existing sheet (`LabelPickerSheet`).
  - Ensure the control is disabled/hidden gracefully if `onLabelUpdate == nil` (e.g., history view).
- No model changes required.
- No view model changes required (already has `updateSetLabel`).

## Test plan (manual)
- In an active workout:
  - Add a set, set label to Warmup, verify the UI updates immediately.
  - Change label Warmup → Drop Set, verify persists after leaving/re-entering active workout.
  - Set label back to None, verify UI reflects “unlabeled” but still shows the affordance.
- In read-only contexts (e.g., history):
  - Label control should not allow editing (disabled or not shown).

