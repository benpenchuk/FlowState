# Copy Set Values When Adding New Set

**Status:** Future Enhancement  
**Priority:** Medium-High  
**Estimated Complexity:** Low  
**Date:** January 17, 2026

## Overview

When a user adds a new set below an existing set that already has weight and reps filled in, automatically copy those values to the new set. This reduces data entry friction and matches the common workout pattern where sets often use the same weight/reps.

## Current Behavior

When a user adds a set:

1. User completes Set 1: 135 lbs × 10 reps
2. User taps "Add Set" button
3. New Set 2 is created with **empty values** (reps = nil, weight = nil)
4. User must manually re-enter 135 lbs and 10 reps
5. Repeat for Set 3, Set 4, etc.

**Current Implementation:**

```swift
// In ActiveWorkoutViewModel.swift
func addSetToEntry(_ entry: WorkoutEntry) {
    let sets = entry.getSets()
    let newSetNumber = (sets.max(by: { $0.setNumber < $1.setNumber })?.setNumber ?? 0) + 1
    
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: nil,           // ❌ Always nil
        weight: nil,         // ❌ Always nil
        isCompleted: false,
        label: .none
    )
    
    entry.addSet(newSet)
    
    // Save...
}
```

**User Experience:**
- ✅ Fast to add sets
- ❌ Tedious to re-enter same values
- ❌ Many exercises use same weight across sets
- ❌ Extra taps and typing required

## Proposed Behavior

When a user adds a set, intelligently copy values from the most recent set:

1. User completes Set 1: 135 lbs × 10 reps
2. User taps "Add Set" button
3. New Set 2 is created **pre-filled** with 135 lbs × 10 reps
4. User can immediately:
   - Accept values by marking complete (1 tap)
   - Adjust values if needed (2 taps + edit)
   - Or start fresh if completely different

**Smart Copying Logic:**
```
If previous set has values → copy them
If previous set is empty → look at set before that
If no sets have values → create empty set (current behavior)
```

## Benefits

### User Experience
- **Significantly faster logging:** Eliminate repetitive data entry
- **One-tap completion:** If set matches previous, just tap checkmark
- **Maintains flexibility:** User can still edit values
- **Matches mental model:** Most sets in a series use same weight

### Workout Flow
- **Reduces friction:** Fewer interruptions during rest periods
- **Improves accuracy:** Less typing = fewer errors
- **Better focus:** Spend time lifting, not typing

### Real-World Usage Patterns

**Straight Sets (Most Common):**
```
Set 1: 135 × 10 ✓
Set 2: 135 × 10 ✓  ← Same values
Set 3: 135 × 10 ✓  ← Same values
Set 4: 135 × 10 ✓  ← Same values
```
**Benefit:** 3 sets saved from manual entry

**Pyramid Sets:**
```
Set 1: 135 × 10 ✓
Set 2: 155 × 8  ✓  ← Start with 135×10, adjust to 155×8
Set 3: 175 × 6  ✓  ← Start with 155×8, adjust to 175×6
```
**Benefit:** Still helpful, minor adjustments easier than full entry

**Drop Sets:**
```
Set 1: 185 × 6 ✓
Set 2: 165 × 8 ✓  ← Start with 185×6, adjust down
Set 3: 145 × 10 ✓ ← Start with 165×8, adjust down
```
**Benefit:** Pre-filled values provide starting point

## Implementation

### Option 1: Copy from Previous Set (Recommended)

Copy values from the immediately previous set.

```swift
func addSetToEntry(_ entry: WorkoutEntry) {
    let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
    let newSetNumber = (sets.last?.setNumber ?? 0) + 1
    
    // Get values from last set
    let previousSet = sets.last
    let copyWeight = previousSet?.weight
    let copyReps = previousSet?.reps
    
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: copyReps,      // ✅ Copied from previous
        weight: copyWeight,  // ✅ Copied from previous
        isCompleted: false,
        label: .none
    )
    
    entry.addSet(newSet)
    
    if let modelContext = modelContext {
        do {
            try modelContext.save()
        } catch {
            print("Error adding set: \(error)")
        }
    }
}
```

**Pros:**
- Simple implementation
- Predictable behavior
- Works for all workout styles

**Cons:**
- If previous set is empty, new set is also empty
- Doesn't handle gaps in set completion

### Option 2: Copy from Last Completed Set

Skip empty sets and copy from the last set with values.

```swift
func addSetToEntry(_ entry: WorkoutEntry) {
    let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
    let newSetNumber = (sets.last?.setNumber ?? 0) + 1
    
    // Find last set with actual values (working backwards)
    let lastSetWithValues = sets.reversed().first { set in
        set.weight != nil && set.reps != nil
    }
    
    let copyWeight = lastSetWithValues?.weight
    let copyReps = lastSetWithValues?.reps
    
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: copyReps,
        weight: copyWeight,
        isCompleted: false,
        label: .none
    )
    
    entry.addSet(newSet)
    
    // Save...
}
```

**Pros:**
- Smarter fallback behavior
- Handles partially completed exercises
- More resilient to user workflow variations

**Cons:**
- Slightly more complex
- Might be surprising if user deliberately left a set empty

### Option 3: Copy Only If Previous Set is Complete

Only copy values if the previous set is marked as completed.

```swift
func addSetToEntry(_ entry: WorkoutEntry) {
    let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
    let newSetNumber = (sets.last?.setNumber ?? 0) + 1
    
    // Only copy if previous set is completed
    let previousSet = sets.last
    var copyWeight: Double? = nil
    var copyReps: Int? = nil
    
    if previousSet?.isCompleted == true {
        copyWeight = previousSet?.weight
        copyReps = previousSet?.reps
    }
    
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: copyReps,
        weight: copyWeight,
        isCompleted: false,
        label: .none
    )
    
    entry.addSet(newSet)
    
    // Save...
}
```

**Pros:**
- Respects workout flow
- Only copies from "finalized" sets
- Prevents copying from in-progress sets

**Cons:**
- User might add set before marking previous complete
- More restrictive behavior

### Option 4: Smart Copy with Fallback Chain

Try multiple strategies in order of preference.

```swift
func addSetToEntry(_ entry: WorkoutEntry) {
    let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
    let newSetNumber = (sets.last?.setNumber ?? 0) + 1
    
    var copyWeight: Double? = nil
    var copyReps: Int? = nil
    
    // Strategy 1: Copy from immediately previous set if it has values
    if let lastSet = sets.last, 
       lastSet.weight != nil && lastSet.reps != nil {
        copyWeight = lastSet.weight
        copyReps = lastSet.reps
    }
    // Strategy 2: Find last completed set with values
    else if let lastCompletedSet = sets.reversed().first(where: { 
        $0.isCompleted && $0.weight != nil && $0.reps != nil 
    }) {
        copyWeight = lastCompletedSet.weight
        copyReps = lastCompletedSet.reps
    }
    // Strategy 3: Find any set with values (last resort)
    else if let anySetWithValues = sets.reversed().first(where: {
        $0.weight != nil && $0.reps != nil
    }) {
        copyWeight = anySetWithValues.weight
        copyReps = anySetWithValues.reps
    }
    // Strategy 4: Leave empty (current behavior)
    
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: copyReps,
        weight: copyWeight,
        isCompleted: false,
        label: .none
    )
    
    entry.addSet(newSet)
    
    // Save...
}
```

**Pros:**
- Most intelligent behavior
- Handles all edge cases
- Graceful fallback to current behavior

**Cons:**
- Most complex implementation
- Might be overkill for simple use case

## Recommended Approach

**Start with Option 1 (Copy from Previous Set), monitor usage, consider Option 4 if issues arise**

### Rationale:
- Option 1 is simple and handles 90% of use cases
- Easy to understand and predict
- Can always enhance later with smarter fallbacks
- Low risk of surprising users

### Implementation Steps:

1. **Modify `addSetToEntry` in ActiveWorkoutViewModel**
   - Add logic to copy from previous set
   - Maintain backward compatibility

2. **Test thoroughly**
   - Verify copying works correctly
   - Ensure user can still edit copied values
   - Test with empty sets, partial sets

3. **Add user feedback**
   - Brief animation or highlight when values are copied
   - Optional: Show subtle indicator "Copied from Set X"

4. **Monitor and iterate**
   - Track user behavior with copied sets
   - Adjust logic if needed

## Edge Cases to Consider

### 1. First Set of Exercise

**Scenario:** Exercise has no sets yet, user adds first set

**Solution:** No previous set to copy from, create empty set (current behavior)

```swift
if sets.isEmpty {
    // First set, no copying
    createEmptySet()
}
```

### 2. Previous Set is Empty

**Scenario:** User added Set 1 but hasn't filled it in yet, then adds Set 2

**Option A (Simple):** Copy nil values → Set 2 is also empty
**Option B (Smart):** Look further back for values, or leave empty

**Recommendation:** Option A for simplicity

### 3. User is Mid-Edit on Previous Set

**Scenario:** User is currently editing Set 1 weight when they tap "Add Set"

**Solution:** Copy whatever values exist at that moment (might be incomplete)

**Alternative:** Disable "Add Set" button while editing (not recommended - too restrictive)

### 4. Partial Values

**Scenario:** Previous set has weight but no reps (or vice versa)

**Solution:** Copy whatever values exist:
```swift
copyWeight = previousSet?.weight  // Might be nil
copyReps = previousSet?.reps      // Might be nil
```

User can fill in missing value.

### 5. Set Labels

**Scenario:** Previous set has label (warmup, failure, etc.)

**Question:** Should label be copied too?

**Recommendation:** **No, don't copy labels**
- Labels are typically unique to specific sets
- Warmup → working sets should not copy label
- Failure sets are usually last set only
- PR attempts are typically specific sets

**Exception:** Could copy "dropSet" label since drop sets are sequential

```swift
// Don't copy label by default
let newSet = SetRecord(
    setNumber: newSetNumber,
    reps: copyReps,
    weight: copyWeight,
    isCompleted: false,
    label: .none  // Always start with no label
)
```

### 6. Units Conversion

**Scenario:** User has preferred units set to kg, but previous workout was in lbs

**Solution:** Weight is stored in lbs internally, so this is handled automatically by the model layer. No special handling needed.

### 7. Very Large Set Numbers

**Scenario:** Exercise has 10+ sets (e.g., German Volume Training)

**Solution:** Copying still makes sense - GVT uses same weight across all sets

### 8. User Deletes and Re-adds Set

**Scenario:** 
1. User has Set 1, 2, 3
2. User deletes Set 2
3. User adds new set

**Question:** Should new set be Set 2 or Set 4?

**Current Behavior:** New set gets next number (4)

**With Copying:** Copy from Set 3 (most recent)

**Recommendation:** Keep current set numbering logic, copy from highest set number

### 9. Reordering Sets with Drag-and-Drop

**Scenario:**
1. User has Set 1 (135×10), Set 2 (135×10), Set 3 (155×8)
2. User drags Set 3 to position 2
3. Order is now: Set 1 (135×10), Set 3 (155×8), Set 2 (135×10)
4. User adds new set

**Question:** Copy from Set 2 (last by number) or Set 3 (last by position)?

**Recommendation:** Copy from last by **position** (visual order)

```swift
let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
let lastSetByPosition = sets.last  // Already sorted by setNumber
```

Wait, this needs clarification - if sets are reordered, their setNumbers don't change (they just get rendered in different order).

**Better Approach:** Copy from the set that's visually last in the list (highest setNumber)

### 10. Auto-Advance Feature Interaction

**Scenario:** User has auto-advance enabled (from `KNOWN_ISSUES.md`)

When user completes Set 1:
1. Auto-advance scrolls to Set 2
2. Set 2 already has copied values from Set 1
3. User can immediately start completing Set 2

**Result:** Even better UX with both features combined!

## Visual Feedback

### Option A: Subtle Highlight (Recommended)

When a set is added with copied values, briefly highlight the copied fields:

```swift
@State private var showCopiedHighlight: Bool = false

// After adding set with copied values
if copyWeight != nil || copyReps != nil {
    showCopiedHighlight = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        showCopiedHighlight = false
    }
}

// In SetRowView
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .stroke(Color.blue.opacity(showCopiedHighlight ? 0.4 : 0), lineWidth: 2)
)
```

### Option B: Inline Badge

Show small indicator that values were copied:

```swift
HStack {
    fieldBox(...)
    if wasCopied {
        Image(systemName: "doc.on.doc")
            .font(.caption2)
            .foregroundStyle(.blue)
            .opacity(0.6)
    }
}
```

### Option C: No Visual Feedback

Just copy silently. Users will notice values are filled and understand.

**Recommendation:** Option C (silent) or Option A (subtle highlight) for first version

## User Settings (Optional)

Add preference to disable auto-copy:

```swift
// In UserProfile.swift
var autoCopySetValues: Bool = true  // Default enabled

// In SettingsView.swift
Toggle("Auto-copy set values", isOn: $profile.autoCopySetValues)
    .help("When adding a new set, automatically copy weight and reps from the previous set")
```

**Recommendation:** Not necessary for MVP. Only add if users complain about the behavior.

## Testing Requirements

### Functional Tests

#### Basic Functionality
- [ ] Add set after set with values → values are copied
- [ ] Add set after empty set → new set is empty
- [ ] Add first set to exercise → set is empty (no previous to copy)
- [ ] Copy preserves weight units correctly
- [ ] Copy preserves reps correctly
- [ ] New set is not marked as completed
- [ ] New set has no label (even if previous has label)

#### Edge Cases
- [ ] Add set with partial values (only weight or only reps) → copies what exists
- [ ] Add multiple sets rapidly → each copies from correct previous
- [ ] Add set after deleting a set → copies from remaining last set
- [ ] Add set when only Set 1 exists → copies from Set 1
- [ ] Add set when multiple sets exist → copies from highest number

#### Integration Tests
- [ ] Works with auto-advance feature
- [ ] Works with drag-and-drop reordering
- [ ] Works with undo/redo (if implemented)
- [ ] Works with set labels
- [ ] Works across different exercises
- [ ] Persists correctly after save
- [ ] Survives app restart

#### Performance Tests
- [ ] No lag when adding sets with copying
- [ ] No issues with exercises with many sets (10+)
- [ ] State updates propagate correctly to UI

### User Acceptance Tests

#### Workflow Tests
- [ ] Complete Set 1, add Set 2 → fast and intuitive
- [ ] Add Set 2 with different values → easy to edit
- [ ] Add multiple sets of same exercise → smooth flow
- [ ] Works naturally with rest timer
- [ ] Doesn't interfere with manual data entry

## Alternative Behaviors to Consider

### 1. Copy on Completion Instead of Add

**Behavior:** When Set 1 is marked complete, automatically create Set 2 with same values

**Pros:**
- Even less friction
- Anticipates user's next action
- One less tap

**Cons:**
- Assumes user wants another set
- What if last set is different (e.g., AMRAP)?
- User might want to do different exercise next

**Verdict:** Too aggressive, keep manual "Add Set" button

### 2. Smart Suggestions

**Behavior:** Show "Add Set (135×10)" button with preview

```swift
Button {
    addSetToEntry(entry)
} label: {
    HStack {
        Image(systemName: "plus.circle")
        if let lastSet = sets.last, 
           let w = lastSet.weight, 
           let r = lastSet.reps {
            Text("Add Set (\(Int(w))×\(r))")
        } else {
            Text("Add Set")
        }
    }
}
```

**Pros:**
- User knows what will happen
- More transparent
- Good for discoverability

**Cons:**
- Button text changes dynamically
- Longer button text
- Might be distracting

**Verdict:** Nice enhancement for future, not MVP

### 3. Copy from Last Session

**Behavior:** When adding sets to new exercise, copy from last workout's same exercise

**Pros:**
- Progressive overload support
- Consistent with workout history
- Very smart behavior

**Cons:**
- Complex implementation
- Requires historical data
- Might not be appropriate (e.g., deload weeks)

**Verdict:** Too complex for this feature, consider separately

## User Flow Comparison

### Before (Current)

**Scenario:** Bench Press - 3 sets of 135×10

```
1. Add Set 1
2. Enter 135 for weight → 3 taps (numpad: 1, 3, 5, Done)
3. Enter 10 for reps → 2 taps (numpad: 1, 0, Done)
4. Mark complete → 1 tap
5. Add Set 2
6. Enter 135 for weight → 3 taps
7. Enter 10 for reps → 2 taps
8. Mark complete → 1 tap
9. Add Set 3
10. Enter 135 for weight → 3 taps
11. Enter 10 for reps → 2 taps
12. Mark complete → 1 tap

Total: 18 taps for 3 sets
```

### After (Proposed)

**Scenario:** Bench Press - 3 sets of 135×10

```
1. Add Set 1
2. Enter 135 for weight → 3 taps
3. Enter 10 for reps → 2 taps
4. Mark complete → 1 tap
5. Add Set 2 [auto-populated with 135×10]
6. Mark complete → 1 tap (values already filled!)
7. Add Set 3 [auto-populated with 135×10]
8. Mark complete → 1 tap

Total: 11 taps for 3 sets
```

**Savings:** 7 taps (39% reduction)

### If Values Need Adjustment

**Scenario:** Pyramid set - 135×10, 155×8, 175×6

```
1. Add Set 1
2. Enter 135 for weight → 3 taps
3. Enter 10 for reps → 2 taps
4. Mark complete → 1 tap
5. Add Set 2 [starts with 135×10]
6. Edit weight to 155 → 3 taps
7. Edit reps to 8 → 1 tap
8. Mark complete → 1 tap
9. Add Set 3 [starts with 155×8]
10. Edit weight to 175 → 3 taps
11. Edit reps to 6 → 1 tap
12. Mark complete → 1 tap

Total: 17 taps for 3 sets
```

**Savings:** 1 tap (6% reduction)

Still saves time, plus starting values provide context!

## Implementation Locations

### Files to Modify

**Core Implementation:**
```
FlowState/ViewModels/ActiveWorkoutViewModel.swift
- Modify addSetToEntry() method
- Add logic to copy from previous set
```

**Visual Feedback (Optional):**
```
FlowState/Views/SetRowView.swift
- Add animation/highlight for copied values
```

**Tests:**
```
FlowStateTests/ActiveWorkoutViewModelTests.swift
- Add unit tests for copy logic
```

**Documentation:**
```
docs/development/FEATURES.md
- Document auto-copy behavior
```

## Code Example - Complete Implementation

```swift
// In ActiveWorkoutViewModel.swift

func addSetToEntry(_ entry: WorkoutEntry) {
    guard let modelContext = modelContext else { return }
    
    let sets = entry.getSets().sorted { $0.setNumber < $1.setNumber }
    let newSetNumber = (sets.last?.setNumber ?? 0) + 1
    
    // Get values from previous set (if any)
    let previousSet = sets.last
    let copyWeight = previousSet?.weight
    let copyReps = previousSet?.reps
    
    // Create new set with copied values
    let newSet = SetRecord(
        setNumber: newSetNumber,
        reps: copyReps,      // Will be nil if no previous set or previous set empty
        weight: copyWeight,  // Will be nil if no previous set or previous set empty
        isCompleted: false,
        label: .none         // Never copy labels
    )
    
    entry.addSet(newSet)
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding set: \(error)")
    }
}
```

That's it! Clean and simple.

## Migration and Rollout

### Backward Compatibility
- No database changes required
- No API changes
- Pure logic change in view model
- Safe to deploy immediately

### Rollout Strategy
1. Deploy in beta to test users
2. Gather feedback on behavior
3. Adjust if needed (add smarter fallbacks)
4. Roll out to all users
5. Monitor usage patterns

### Rollback Plan
If users dislike the behavior:
```swift
// Temporarily disable by changing to:
let copyWeight: Double? = nil
let copyReps: Int? = nil
// And deploy hotfix
```

## Success Metrics

### Quantitative (if analytics available)
- Time per set entry decreases
- "Add Set" to "Complete Set" duration decreases
- Number of edits per set (should stay same or decrease)
- User complaints/support tickets (should not increase)

### Qualitative
- User feedback positive
- No confusion about copied values
- Feature feels natural and intuitive
- Users don't request disable option

## Related Features

### Synergy with AUTO_POPULATE_EXERCISE_SETS
If exercises start with 3 pre-populated sets:
- Set 1, 2, 3 all start empty (as proposed in that feature)
- User fills Set 1
- **But Sets 2 and 3 still empty**

This feature would enhance that:
- User fills Set 1, marks complete
- When user adds Set 4, it copies from Set 3

**Alternative Enhancement:**
When user marks Set 1 complete, auto-copy to Set 2 and Set 3:
```swift
func updateSet(..., isCompleted: Bool) {
    // Existing update logic
    
    // If this is first set being completed, copy to subsequent empty sets
    if isCompleted && set.setNumber == 1 {
        let subsequentEmptySets = entry.getSets()
            .filter { $0.setNumber > 1 && $0.weight == nil && $0.reps == nil }
        
        for emptySet in subsequentEmptySets {
            emptySet.weight = set.weight
            emptySet.reps = set.reps
        }
    }
}
```

This would be **very** smart but might be too magical. Consider as future enhancement.

## Conclusion

Auto-copying set values is a low-complexity, high-impact feature that will:
- Significantly reduce data entry friction
- Speed up workout logging
- Maintain flexibility for users who need different values
- Align with real-world workout patterns (straight sets)

**Recommendation:** Implement Option 1 (Simple Copy from Previous) in next sprint.

**Estimated Development Time:**
- Implementation: 30 minutes
- Testing: 1 hour
- Total: ~1.5 hours

**ROI:** Extremely high - minimal dev time for substantial UX improvement.

---

**Related Documentation:**
- [AUTO_POPULATE_EXERCISE_SETS.md](AUTO_POPULATE_EXERCISE_SETS.md) - Synergistic feature
- [FEATURES.md](../../development/FEATURES.md)
- [MODELS.md](../../architecture/MODELS.md)
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Auto-advance feature
