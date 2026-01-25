# Set Labels Future Enhancements

## Overview

This document tracks deferred and future enhancement ideas for the set labeling system. The core labeling system has been simplified to 3 labels (None, Warmup, Drop Set), with letter indicators and long-press interaction. These enhancements represent additional features that could improve the labeling workflow but need user validation before implementation.

---

## Deferred: Smart Label Defaults

### Concept

When adding a new set during an active workout, automatically copy the label from the previous set if it makes contextual sense.

### Logic

```
IF previous set label is:
  - warmup → new set = .none (warmups are typically at the start)
  - dropSet → new set = .dropSet (drop sets are sequential by nature)
  - none → new set = .none (working sets remain unlabeled)
```

### Special Cases

- If ALL existing sets in the exercise are labeled as warmup, the next set should also default to warmup (still in warmup phase)
- After completing warmup sets and adding a new set, switch to `.none` (entering working sets)

### Rationale for Deferring

This feature was deferred because:
1. Need to validate whether users actually want this behavior through testing
2. Automatic labeling might surprise users who expect explicit control
3. The drop set use case (sequential) is common, but the warmup logic is more complex
4. Current manual labeling is simple enough that automation may not add significant value

### Implementation Notes

If implemented, modify `addSetToEntry(_ entry: WorkoutEntry)` in `ActiveWorkoutViewModel.swift`:

```swift
func addSetToEntry(_ entry: WorkoutEntry) {
    guard let modelContext = modelContext else { return }
    
    var sets = entry.getSets()
    let nextSetNumber = sets.count + 1
    
    // Smart default: copy label if previous set was a drop set
    let previousLabel = sets.last?.label ?? .none
    let defaultLabel: SetLabel = (previousLabel == .dropSet) ? .dropSet : .none
    
    let newSet = SetRecord(
        setNumber: nextSetNumber,
        reps: nil,
        weight: nil,
        isCompleted: false,
        label: defaultLabel
    )
    sets.append(newSet)
    entry.setSets(sets)
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding set: \(error)")
    }
}
```

---

## Future: Bulk Label Operations

### Problem

Marking multiple sets with the same label (e.g., 3 warmup sets) requires 3 separate long-press + select operations.

### Proposed Solutions

#### Option A: Quick Label Button on Exercise Header

Add a context menu or button to the exercise card header:
- "Mark All as Warmup"
- "Mark All as Drop Set"
- "Clear All Labels"

**Pros:**
- Fast for common use case (labeling all sets)
- Discoverable location
- No new UI patterns needed

**Cons:**
- Less precise (affects all sets, not a subset)
- Need to add individual undo if user only wants some sets labeled

#### Option B: Multi-Select Mode

Add a "Select Sets" mode:
1. Tap "Select" button on exercise header
2. Tap checkboxes next to sets to select multiple
3. Apply label to all selected sets
4. Tap "Done" to exit selection mode

**Pros:**
- Precise control over which sets get labeled
- Familiar pattern (iOS multi-select)
- Works for any batch operation (delete, label, etc.)

**Cons:**
- More complex UI state
- Requires additional selection mode UI
- May be overkill if only used for labels

#### Option C: "Label Above/Below" Context Menu

Long-press a set shows:
- Current label options (None, Warmup, Drop Set)
- "Apply to Sets Above"
- "Apply to Sets Below"

**Pros:**
- Contextual and precise
- No new modes or buttons needed
- Natural extension of existing long-press gesture

**Cons:**
- Hidden in context menu (less discoverable)
- "Above/Below" language might be confusing

### Recommendation

Start with **Option A** (quick button on header) for the most common case (labeling all warmup sets at once). If user feedback shows need for more precision, add Option C for advanced control.

---

## Future: Workout View Preferences

### Concept

Different users have different tracking needs and workout styles. Instead of a one-size-fits-all UI, allow users to customize their active workout view to match their training style.

### View Mode Examples

#### 1. Minimalist Mode
**Target User:** Casual lifters, beginners
**Features:**
- Hide set labels entirely
- Hide last session comparison
- Simplified UI with larger tap targets
- Focus only on weight/reps logging

#### 2. Detailed Mode (Default)
**Target User:** General fitness enthusiasts
**Features:**
- Show all features (current behavior)
- Set labels visible
- Last session comparison
- Rest timer
- Notes available

#### 3. Powerlifter Mode
**Target User:** Strength athletes, powerlifters
**Features:**
- Emphasize warmup tracking (warmup labels prominent)
- Show percentage of 1RM
- Longer rest timer defaults
- Focus on weight progression

#### 4. Bodybuilder Mode
**Target User:** Bodybuilders, hypertrophy focus
**Features:**
- Emphasize drop sets and failure sets
- Time under tension tracking
- Volume tracking (total reps × weight)
- Shorter rest timer defaults

#### 5. Athlete Mode
**Target User:** Sports performance, functional training
**Features:**
- Cardio integration
- Interval timer
- Movement quality notes
- RPE (Rate of Perceived Exertion) tracking

### Implementation Approach

1. **User Profile Setting:**
   ```swift
   enum WorkoutViewStyle: String, Codable, CaseIterable {
       case minimalist = "Minimalist"
       case detailed = "Detailed"
       case powerlifter = "Powerlifter"
       case bodybuilder = "Bodybuilder"
       case athlete = "Athlete"
   }
   ```

2. **Profile Model:**
   Add `preferredWorkoutViewStyle: WorkoutViewStyle` to `UserProfile` model

3. **Conditional UI:**
   ```swift
   if profileViewModel.profile?.preferredWorkoutViewStyle == .minimalist {
       // Hide labels, simplify UI
   } else {
       // Show full feature set
   }
   ```

4. **Settings Screen:**
   Add "Workout View" picker in Profile/Settings
   Include preview/description of each style

### UI Density Settings

In addition to view styles, allow granular control:
- **Compact:** Smaller padding, more sets visible
- **Standard:** Current spacing
- **Comfortable:** Larger tap targets, more spacing

### Feature Toggles

Instead of (or in addition to) preset modes, allow users to toggle individual features:
- [ ] Show set labels
- [ ] Show last session comparison
- [ ] Show rest timer in header
- [ ] Auto-start rest timer on set completion
- [ ] Show PR notifications
- [ ] Show exercise instructions
- [ ] Show equipment icons

### Migration from Current System

The current implementation is effectively "Detailed Mode". When view preferences are added:
1. Default new users to "Detailed"
2. Allow existing users to switch modes in settings
3. Preserve all data regardless of view mode (hidden features still function)

### Testing Approach

1. Implement basic view style switching (minimalist vs detailed)
2. A/B test with different user segments
3. Gather feedback on which features users want to toggle
4. Iterate on preset modes vs granular toggles approach

---

## Future: Label Color Coding (Revisited)

### Current State

Letter indicators (W, D) are plain text in secondary color. No colored circles/dots.

### Future Consideration

If user feedback shows that letter-only indicators are too subtle, consider:
- Colored text instead of colored circles (less intrusive)
- Subtle background tint for labeled sets
- Icon + letter combination (e.g., flame icon + "D" for drop set)

### Testing Required

Monitor user feedback on:
- Can users easily distinguish warmup vs working sets?
- Do users notice the labels without color?
- Are the letters W/D intuitive or confusing?

---

## Future: Pre-Planning Set Labels in Templates

### Current State

Templates support configuring labels for each set (e.g., "Set 1 = Warmup, Set 2 = Warmup, Set 3-5 = None").

### Enhancement Ideas

#### Smart Template Presets
When creating a template, offer quick presets:
- "First 2 sets warmup" → automatically labels set 1-2 as warmup
- "Last 2 sets drop sets" → automatically labels last 2 as drop
- "Pyramid" → custom label pattern

#### Label Pattern Editor
Visual editor for complex label patterns:
```
[W] [W] [ ] [ ] [D] [D]
Set 1-2: Warmup
Set 3-4: Working
Set 5-6: Drop
```

---

## Implementation Priority

1. **High Priority (User-Requested):**
   - Bulk label operations (Option A: quick button on header)
   - Monitor feedback on letter-only indicators

2. **Medium Priority (Nice-to-Have):**
   - Smart label defaults (if users report frustration with manual labeling)
   - Basic view mode switching (minimalist vs detailed)

3. **Low Priority (Future Vision):**
   - Full workout view customization system
   - Advanced template label patterns
   - Color coding revisit (only if letter indicators fail)

---

## User Feedback Tracking

To validate these enhancements, track:
- How often do users change set labels?
- Which labels are used most (warmup vs drop)?
- Do users label sets before or after logging weight/reps?
- Are there patterns in how many sets get the same label?
- User complaints/feature requests related to labeling workflow

---

## Related Documents

- `docs/FEATURES.md` - Current feature documentation
- `docs/futureTasks/SET_LABELS_DISCOVERABILITY.md` - Original discoverability problem
- `FlowState/Models/SetRecord.swift` - SetLabel enum definition
- `FlowState/Views/SetRowView.swift` - Label indicator UI
