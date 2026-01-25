# Auto-Populate Exercise Sets on Add

**Status:** ✅ COMPLETED  
**Priority:** Medium  
**Estimated Complexity:** Low  
**Original Date:** January 17, 2026  
**Completed Date:** January 24, 2026

---

## ✅ Implementation Summary

This feature has been **successfully implemented** with a smart, history-aware approach.

**What Was Built:**
- Smart default sets that pre-fill from workout history when available
- Fallback to 3 empty sets for exercises with no history
- Automatic set count matching (if user did 5 sets last time, creates 5 this time)
- Zero configuration required - works automatically

**Implementation Approach:**
- Simplified 2-priority system (history → empty sets)
- Leveraged existing `getLastSessionSets()` method for history lookup
- No template integration in initial version (simpler, more focused)
- Added comprehensive future enhancements documentation

**Files Modified:**
- `FlowState/ViewModels/ActiveWorkoutViewModel.swift`
  - Added `createSmartDefaultSets(for:)` helper method
  - Updated `addExerciseToWorkout(_:)` to use smart defaults
- `docs/FEATURES.md` - Documented new behavior
- `docs/futureTasks/SMART_DEFAULT_SETS_ENHANCEMENTS.md` - Future enhancement ideas

**Related Documentation:**
- See [SMART_DEFAULT_SETS_ENHANCEMENTS.md](./SMART_DEFAULT_SETS_ENHANCEMENTS.md) for 15+ future enhancement possibilities

---

## Original Proposal

## Overview

Automatically create a default number of sets (e.g., 3 sets) when a user adds an exercise to an active workout, reducing friction and improving workout flow.

## Current Behavior

When a user adds an exercise to an active workout:

1. User taps "Add Exercise" button in `ActiveWorkoutFullScreenView`
2. `AddExerciseToWorkoutSheet` appears
3. User selects an exercise
4. Exercise is added to workout with **0 sets**
5. User must manually tap "Add Set" button for each set they want
6. User typically adds 3-4 sets per exercise

**Current Implementation:**
```swift
// In AddExerciseToWorkoutSheet
viewModel.addExercise(exercise, to: workoutState.activeWorkout!)
```

**In ActiveWorkoutViewModel:**
```swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    guard let modelContext = modelContext else { return }
    
    let entry = WorkoutEntry(
        workout: workout,
        exercise: exercise,
        order: (workout.entries?.count ?? 0)
    )
    
    modelContext.insert(entry)
    // Note: No sets are created here
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding exercise: \(error)")
    }
}
```

## Proposed Behavior

When a user adds an exercise, automatically create 3 empty sets:

1. User selects exercise from sheet
2. Exercise is added with **3 pre-populated sets** (set numbers 1, 2, 3)
3. Sets have `reps = nil`, `weight = nil`, `isCompleted = false`
4. User can immediately start logging without extra taps
5. User can still add/remove sets as needed

## Benefits

### User Experience
- **Reduces friction:** No need to tap "Add Set" 3 times per exercise
- **Faster workout logging:** Get straight to entering weight/reps
- **Matches mental model:** Most exercises are 3-4 sets
- **Maintains flexibility:** Users can still adjust set count

### Workflow Improvement
- **Fewer taps:** Save 3 taps per exercise
- **Better flow state:** Less interruption during workout
- **Progressive disclosure:** Pre-populate common case, allow customization

## Implementation

### Option 1: Fixed Default (Simple)

Always create 3 sets when exercise is added.

```swift
func addExercise(_ exercise: Exercise, to workout: Workout, defaultSetCount: Int = 3) {
    guard let modelContext = modelContext else { return }
    
    let entry = WorkoutEntry(
        workout: workout,
        exercise: exercise,
        order: (workout.entries?.count ?? 0)
    )
    
    modelContext.insert(entry)
    
    // Auto-create default sets
    for i in 1...defaultSetCount {
        let set = SetRecord(
            setNumber: i,
            reps: nil,
            weight: nil,
            isCompleted: false,
            label: .none
        )
        entry.addSet(set)
    }
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding exercise: \(error)")
    }
}
```

**Pros:**
- Simple to implement
- Consistent behavior
- Predictable for users

**Cons:**
- Not personalized
- Some exercises might need different counts (e.g., warm-up exercises)

### Option 2: User Preference (Configurable)

Add user setting for default set count.

**In UserProfile model:**
```swift
@Model
final class UserProfile {
    // ... existing properties ...
    var defaultSetCount: Int = 3 // New property
}
```

**In ProfileView settings:**
```swift
Section("Workout Defaults") {
    Stepper("Default Sets: \(profile.defaultSetCount)", 
            value: $profile.defaultSetCount, 
            in: 1...10)
}
```

**In addExercise:**
```swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    guard let modelContext = modelContext else { return }
    
    // Get user preference or default to 3
    let defaultSetCount = profileViewModel?.profile?.defaultSetCount ?? 3
    
    let entry = WorkoutEntry(
        workout: workout,
        exercise: exercise,
        order: (workout.entries?.count ?? 0)
    )
    
    modelContext.insert(entry)
    
    // Auto-create sets based on preference
    for i in 1...defaultSetCount {
        let set = SetRecord(
            setNumber: i,
            reps: nil,
            weight: nil,
            isCompleted: false,
            label: .none
        )
        entry.addSet(set)
    }
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding exercise: \(error)")
    }
}
```

**Pros:**
- Personalized to user's training style
- Flexible for different workout types
- One-time configuration

**Cons:**
- Requires settings UI
- Adds complexity
- Users might not discover setting

### Option 3: Smart Default (Context-Aware)

Use last session's set count for this exercise, or default to 3.

```swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    guard let modelContext = modelContext else { return }
    
    // Try to get last set count for this exercise
    let lastSetCount = getLastSetCount(for: exercise) ?? 3
    
    let entry = WorkoutEntry(
        workout: workout,
        exercise: exercise,
        order: (workout.entries?.count ?? 0)
    )
    
    modelContext.insert(entry)
    
    for i in 1...lastSetCount {
        let set = SetRecord(
            setNumber: i,
            reps: nil,
            weight: nil,
            isCompleted: false,
            label: .none
        )
        entry.addSet(set)
    }
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding exercise: \(error)")
    }
}

private func getLastSetCount(for exercise: Exercise) -> Int? {
    guard let modelContext = modelContext else { return nil }
    
    let descriptor = FetchDescriptor<WorkoutEntry>(
        predicate: #Predicate<WorkoutEntry> { entry in
            entry.exercise?.id == exercise.id &&
            entry.workout.completedAt != nil
        },
        sortBy: [SortDescriptor(\.workout.completedAt, order: .reverse)]
    )
    
    do {
        let entries = try modelContext.fetch(descriptor)
        if let lastEntry = entries.first {
            return lastEntry.getSets().count
        }
    } catch {
        print("Error fetching last set count: \(error)")
    }
    
    return nil
}
```

**Pros:**
- Adapts to user's actual patterns
- No configuration needed
- Learns from history

**Cons:**
- More complex implementation
- Requires historical data
- Might surprise users if they changed patterns

### Option 4: Copy from Template (Template-Aware)

If workout was started from a template, copy set count from template exercise.

```swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    guard let modelContext = modelContext else { return }
    
    // Check if exercise exists in workout's template
    var defaultSetCount = 3
    if let template = workout.template,
       let templateExercises = template.exercises?.allObjects as? [TemplateExercise],
       let matchingTemplateEx = templateExercises.first(where: { $0.exercise?.id == exercise.id }) {
        // Use template's set configuration
        defaultSetCount = matchingTemplateEx.sets
    }
    
    let entry = WorkoutEntry(
        workout: workout,
        exercise: exercise,
        order: (workout.entries?.count ?? 0)
    )
    
    modelContext.insert(entry)
    
    for i in 1...defaultSetCount {
        let set = SetRecord(
            setNumber: i,
            reps: nil,
            weight: nil,
            isCompleted: false,
            label: .none
        )
        entry.addSet(set)
    }
    
    do {
        try modelContext.save()
    } catch {
        print("Error adding exercise: \(error)")
    }
}
```

**Pros:**
- Consistent with workout structure
- Makes sense if adding to template-based workout
- No extra settings needed

**Cons:**
- Only works for template-based workouts
- Doesn't help for free-form workouts
- Complex to determine "matching" exercise

## Recommended Approach

**Start with Option 1 (Fixed Default of 3 sets), then migrate to Option 2 (User Preference)**

### Phase 1: MVP (Fixed Default)
- Implement simple 3-set default
- Gather user feedback
- See if users delete sets frequently (too many) or add sets (too few)

### Phase 2: Personalization (User Setting)
- Add `defaultSetCount` to UserProfile
- Add setting in ProfileView
- Use preference in addExercise

### Future Enhancement: Smart Defaults
- Track user patterns per exercise
- Surface insights ("You usually do 4 sets of Bench Press")
- Optionally implement Option 3 or 4

## Edge Cases to Consider

### 1. User Adds Exercise Multiple Times
**Scenario:** User adds same exercise twice in one workout (e.g., morning and evening split)

**Solution:** Still auto-populate sets. Each entry is independent.

### 2. User Preference is 0
**Scenario:** User sets default to 0 in settings (doesn't want auto-population)

**Solution:** Respect the preference. If `defaultSetCount == 0`, don't create any sets.

### 3. Template-Based Workout
**Scenario:** Workout started from template already has exercises

**Solution:** Only apply to exercises added after workout starts, not initial template exercises.

### 4. User Deletes All Sets Immediately
**Scenario:** User wants different set count and deletes all auto-created sets

**Solution:**
- Allow deletion (current behavior)
- Consider: Prompt "Change default set count?" if user frequently deletes
- Analytics: Track deletion patterns

### 5. Different Exercise Types
**Scenario:** Some exercises need different set counts (e.g., warm-up, cardio, AMRAP)

**Solution:**
- Phase 1: Use same default for all
- Phase 2: Allow per-exercise-type defaults
- Phase 3: Smart defaults based on exercise category

## User Flow

### Before (Current)
```
1. Tap "Add Exercise" (1 tap)
2. Select exercise from list (1 tap)
3. Tap "Add Set" (1 tap)
4. Tap "Add Set" (1 tap)
5. Tap "Add Set" (1 tap)
6. Total: 5 taps to get 3 sets
```

### After (Proposed)
```
1. Tap "Add Exercise" (1 tap)
2. Select exercise from list (1 tap)
3. [Exercise added with 3 sets automatically]
4. Total: 2 taps to get 3 sets
```

**Savings:** 3 taps per exercise, 60% reduction

For a workout with 5 exercises: 15 taps saved!

## Testing Requirements

### Functional Testing
- [ ] Exercise added with 3 sets automatically
- [ ] Sets have correct setNumber (1, 2, 3)
- [ ] Sets have nil values for reps/weight
- [ ] Sets are not completed by default
- [ ] User can still add additional sets
- [ ] User can delete sets
- [ ] Works for all exercise types

### Integration Testing
- [ ] Works in free-form workout
- [ ] Works in template-based workout
- [ ] Works when workout has 0 exercises
- [ ] Works when workout already has exercises
- [ ] Doesn't interfere with existing exercise entries

### User Preference Testing (Phase 2)
- [ ] Setting persists across app restarts
- [ ] Setting respects min/max bounds
- [ ] Setting updates immediately affect new exercises
- [ ] Setting doesn't affect existing exercises

## UI/UX Considerations

### Onboarding
- First time user adds exercise, show brief tip:
  > "Tip: Exercises are auto-populated with 3 sets. You can add or remove sets as needed."

### Settings Discoverability (Phase 2)
- Label: "Default Sets per Exercise"
- Description: "Number of sets automatically created when adding an exercise"
- Location: Profile → Settings → Workout Defaults

### Visual Feedback
- After adding exercise, briefly highlight the new entry
- Expand the exercise section automatically so user sees the sets
- Focus on first set for immediate data entry

## Analytics to Track

If analytics are implemented:
- Average sets per exercise (validate 3 is good default)
- How often users add sets after auto-population
- How often users delete sets after auto-population
- Correlation between exercise type and set count

## Alternative: Ask User on Add

Instead of automatic, prompt user:

```swift
.sheet(isPresented: $showingAddExercise) {
    AddExerciseToWorkoutSheet(
        viewModel: viewModel,
        onExerciseSelected: { exercise in
            // Show action sheet
            showSetCountPicker = true
            selectedExercise = exercise
        }
    )
}

.confirmationDialog("How many sets?", isPresented: $showSetCountPicker) {
    Button("3 sets (recommended)") { addExercise(exercise, setCount: 3) }
    Button("4 sets") { addExercise(exercise, setCount: 4) }
    Button("5 sets") { addExercise(exercise, setCount: 5) }
    Button("Custom") { showCustomSetPicker = true }
    Button("0 sets (I'll add later)") { addExercise(exercise, setCount: 0) }
}
```

**Pros:**
- Explicit control
- No surprises
- Learns user preference quickly

**Cons:**
- Adds friction (extra dialog)
- Interrupts flow
- Might be annoying for experienced users

**Verdict:** Not recommended. Automatic is better than prompting every time.

## Migration Path

### Current State
```swift
// ActiveWorkoutViewModel.swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    // Creates entry with 0 sets
}
```

### Step 1: Add Parameter (Backward Compatible)
```swift
func addExercise(_ exercise: Exercise, to workout: Workout, defaultSetCount: Int = 3) {
    // Creates entry with N sets
}
```

### Step 2: Update Call Sites
```swift
// AddExerciseToWorkoutSheet
viewModel.addExercise(exercise, to: workout) // Uses default 3

// Or explicitly:
viewModel.addExercise(exercise, to: workout, defaultSetCount: 3)
```

### Step 3: Add User Preference (Phase 2)
```swift
func addExercise(_ exercise: Exercise, to workout: Workout) {
    let defaultSetCount = profileViewModel?.profile?.defaultSetCount ?? 3
    // ... create sets
}
```

## Related Features

### Smart Set Pre-Population (Future)
Beyond creating empty sets, could pre-populate with last session's data:

```swift
// Instead of nil values
SetRecord(
    setNumber: 1,
    reps: lastSession?.reps,        // Pre-fill from history
    weight: lastSession?.weight,     // Pre-fill from history
    isCompleted: false,
    label: .none
)
```

**Benefits:** Even faster logging
**Challenges:** Requires last session lookup, might not always be appropriate

### Template Creation from Workout
When saving workout as template, use actual set count rather than fixed count.

### Progressive Set Suggestions
"You did 4 sets last time, want to add a 4th?"

## Files to Modify

### Core Implementation
- `FlowState/ViewModels/ActiveWorkoutViewModel.swift` - Add set creation logic
- `FlowState/Views/AddExerciseToWorkoutSheet.swift` - Call updated method

### User Preference (Phase 2)
- `FlowState/Models/UserProfile.swift` - Add defaultSetCount property
- `FlowState/Views/ProfileView.swift` - Add setting UI
- `FlowState/Views/SettingsView.swift` - Maybe add here instead

### Documentation
- `docs/FEATURES.md` - Document new behavior
- `docs/MODELS.md` - Update UserProfile schema

## Success Metrics

### Qualitative
- Users report faster workout logging
- Positive feedback on reduced friction
- No complaints about wrong defaults

### Quantitative (if analytics available)
- Time from "Add Exercise" to "Complete First Set" decreases
- Number of "Add Set" taps per workout decreases
- User engagement with active workout increases

## Conclusion

Auto-populating exercises with 3 sets is a low-complexity, high-impact improvement that will:
- Save users time during workouts
- Reduce cognitive load and taps
- Maintain flexibility (users can still customize)
- Align with common exercise patterns

**Recommendation:** Implement Option 1 (Fixed 3 sets) in next sprint, then add Option 2 (User Preference) based on feedback.

---

**Related Documentation:**
- [FEATURES.md](../FEATURES.md)
- [MODELS.md](../MODELS.md)
- [ACTIVE_WORKOUT_REFACTOR.md](../pastTasks/ACTIVE_WORKOUT_REFACTOR.md)
