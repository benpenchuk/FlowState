# Smart Default Sets - Future Enhancements

**Status:** Future Enhancement Ideas  
**Priority:** Medium to Low (iterative improvements)  
**Date:** January 24, 2026

## Overview

This document outlines potential enhancements to the smart default sets feature, which currently pre-fills exercises with sets from workout history or creates 3 empty sets as a fallback.

## Current Implementation

**What It Does:**
- When adding an exercise to an active workout, automatically creates sets
- If workout history exists: Creates sets with weight/reps from most recent session
- If no history: Creates 3 empty sets ready for input
- All sets start as not completed (`isCompleted: false`)

**Files Involved:**
- `FlowState/ViewModels/ActiveWorkoutViewModel.swift`
  - `createSmartDefaultSets(for:)` - Creates smart defaults
  - `getLastSessionSets(for:)` - Fetches workout history
  - `addExerciseToWorkout(_:)` - Adds exercise with smart defaults

---

## Enhancement 1: Template-Based Pre-filling

### Problem Statement

When a workout is started from a template and the user adds additional exercises mid-workout, the system doesn't consider template defaults. If the exercise exists in the original template, those prescribed values could be useful.

### Proposed Solution

Track which template (if any) was used to start the workout, and check for template defaults before falling back to history or empty sets.

**Priority System:**
1. Workout history (most recent session)
2. Template defaults (if workout started from template)
3. Empty sets (fallback)

### Implementation

**In Workout Model:**
```swift
@Model
final class Workout {
    // ... existing properties ...
    var sourceTemplateId: UUID? // NEW: Track which template was used
}
```

**In createSmartDefaultSets:**
```swift
private func createSmartDefaultSets(for exercise: Exercise) -> [SetRecord] {
    // Priority 1: History
    let lastSets = getLastSessionSets(for: exercise)
    if !lastSets.isEmpty {
        return /* create from history */
    }
    
    // Priority 2: Template (NEW)
    if let sourceTemplateId = activeWorkout?.sourceTemplateId,
       let templateDefaults = getTemplateDefaults(exerciseId: exercise.id, templateId: sourceTemplateId) {
        return /* create from template */
    }
    
    // Priority 3: Empty
    return /* create 3 empty sets */
}

private func getTemplateDefaults(exerciseId: UUID, templateId: UUID) -> TemplateExercise? {
    // Query template and find matching exercise
}
```

### Complexity: Medium
- Requires schema change (add `sourceTemplateId` to Workout)
- Need to track template on workout creation
- Query template exercises during add operation

### User Benefit: Medium
- Useful when adding exercises that were in the original template
- Maintains workout structure consistency
- Less useful if user rarely adds mid-workout

---

## Enhancement 2: Progressive Overload Auto-Increment

### Problem Statement

Progressive overload is a key training principle - gradually increasing weight over time. Currently, users must manually increase weights each session.

### Proposed Solution

Detect successful completion patterns and suggest automatic weight increments.

**Smart Increment Logic:**
- If last 2-3 sessions all sets completed successfully → suggest +5 lbs
- If user struggled (failure sets) → keep same weight
- If user exceeded target reps consistently → suggest +10 lbs
- Configurable increment amounts in settings (2.5, 5, 10 lbs)

### Implementation

**In createSmartDefaultSets:**
```swift
private func createSmartDefaultSets(for exercise: Exercise) -> [SetRecord] {
    let lastSets = getLastSessionSets(for: exercise)
    if !lastSets.isEmpty {
        let shouldIncrement = shouldSuggestWeightIncrease(for: exercise)
        let incrementAmount = shouldIncrement ? 5.0 : 0.0
        
        return lastSets.enumerated().map { index, lastSet in
            SetRecord(
                setNumber: index + 1,
                reps: lastSet.reps,
                weight: (lastSet.weight ?? 0) + incrementAmount,
                isCompleted: false
            )
        }
    }
    // ... fallback logic
}

private func shouldSuggestWeightIncrease(for exercise: Exercise) -> Bool {
    // Check last 2-3 sessions
    // Return true if all sets completed with target reps or more
}
```

**UI Enhancement:**
Show indicator when weight was auto-incremented:
```
"135 lbs ↑ (from 130 lbs last session)"
```

### Complexity: High
- Requires analyzing multiple workout sessions
- Need to define "success" criteria
- Risk of suggesting too-aggressive increases
- Should be optional (user toggle in settings)

### User Benefit: High
- Automates progressive overload tracking
- Reduces mental load during workouts
- Helps users consistently progress

---

## Enhancement 3: Time-Based Relevance Filtering

### Problem Statement

If a user did an exercise 6 months ago and returns to it, the old weight might be irrelevant (detraining effect). Pre-filling with outdated data could be misleading or demotivating.

### Proposed Solution

Only use workout history if the exercise was performed within a configurable time window (default: 60 days).

### Implementation

**In getLastSessionSets:**
```swift
func getLastSessionSets(for exercise: Exercise, withinDays days: Int = 60) -> [SetRecord] {
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    
    let descriptor = FetchDescriptor<Workout>(
        predicate: #Predicate<Workout> { workout in
            workout.completedAt != nil &&
            workout.completedAt! >= cutoffDate  // NEW: Date filter
        },
        sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    
    // ... rest of logic
}
```

**In UserProfile Model:**
```swift
@Model
final class UserProfile {
    // ... existing properties ...
    var historyRelevanceDays: Int = 60 // NEW: Configurable
}
```

### Complexity: Low
- Simple date comparison in query
- Optional user setting in profile
- No breaking changes

### User Benefit: Medium
- Prevents misleading pre-fills after long breaks
- Forces fresh assessment of current strength
- Can help users ease back into exercises

---

## Enhancement 4: Visual History Indicators

### Problem Statement

Users don't know when pre-filled values came from history vs. being empty. This context would help them decide whether to use or adjust the values.

### Proposed Solution

Show subtle visual indicators when sets are pre-filled from history, including the date of the last session.

### Implementation

**UI Changes in SetRowView:**
```swift
// Add metadata to SetRecord
struct SetRecord {
    // ... existing properties ...
    var sourceInfo: SetSourceInfo? // NEW
}

enum SetSourceInfo {
    case history(date: Date)
    case template(name: String)
    case empty
}
```

**Visual Design:**
- Small badge/pill near first set: "From Jan 20"
- Tappable to see full history
- Different colors: history (blue), template (purple), empty (gray)

### Complexity: Medium
- Requires passing source metadata through to UI
- Need to update SetRecord structure
- UI design and layout work

### User Benefit: High
- Provides context for decision-making
- Increases trust in the feature
- Helps users understand where data came from

---

## Enhancement 5: Quick Adjust Controls

### Problem Statement

Even with pre-filled weights, users often want to make small adjustments (±5 lbs for progressive overload). Currently requires tapping field and entering new value.

### Proposed Solution

Add quick increment/decrement buttons for weight values, especially useful when history is pre-filled.

### Implementation

**UI in SetRowView:**
```swift
HStack {
    Button("-5") {
        weight = max(0, (weight ?? 0) - 5)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    
    TextField("Weight", value: $weight)
    
    Button("+5") {
        weight = (weight ?? 0) + 5
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
}
```

**Configuration:**
- Increment amount based on units (5 lbs / 2.5 kg)
- Settings to customize increment (2.5, 5, 10)
- Long-press for faster increments

### Complexity: Low
- Pure UI addition
- No data model changes
- Easy to implement

### User Benefit: High
- Extremely fast progressive overload
- Reduces tapping and typing
- Better UX for common operation

---

## Enhancement 6: User Preference for Default Set Count

### Problem Statement

Different users and different training styles use different set counts. Some do 3 sets, others do 5, CrossFit athletes might do 1-2 heavy sets.

### Proposed Solution

Add user setting for default set count when no history exists.

### Implementation

**In UserProfile Model:**
```swift
@Model
final class UserProfile {
    // ... existing properties ...
    var defaultSetCount: Int = 3 // NEW: Configurable (1-10)
}
```

**In createSmartDefaultSets:**
```swift
private func createSmartDefaultSets(for exercise: Exercise) -> [SetRecord] {
    let lastSets = getLastSessionSets(for: exercise)
    if !lastSets.isEmpty {
        return /* create from history */
    }
    
    // Use user preference instead of hardcoded 3
    let defaultCount = getUserDefaultSetCount() // or pass from profile
    return (1...defaultCount).map { /* create empty set */ }
}
```

**Settings UI:**
```swift
Section("Workout Defaults") {
    Stepper("Default Sets: \(profile.defaultSetCount)", 
            value: $profile.defaultSetCount, 
            in: 1...10)
    Text("Number of sets created when adding new exercises")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

### Complexity: Low
- Simple property addition
- Settings UI is straightforward
- No complex logic

### User Benefit: Medium
- Personalizes experience to training style
- Reduces friction for users who do 4-5 sets
- One-time configuration

---

## Enhancement 7: Exercise-Type Awareness

### Problem Statement

Different exercise types have different typical set counts:
- Main compounds: 3-5 sets
- Accessories: 2-4 sets
- Warmups: 1-2 sets
- Cardio: 1 set (with duration)

### Proposed Solution

Use exercise category or custom tags to determine appropriate default set counts.

### Implementation

**In Exercise Model (potential addition):**
```swift
@Model
final class Exercise {
    // ... existing properties ...
    var typicalSetCount: Int? // Optional: override default
}
```

**Smart Defaults by Category:**
```swift
private func createSmartDefaultSets(for exercise: Exercise) -> [SetRecord] {
    let lastSets = getLastSessionSets(for: exercise)
    if !lastSets.isEmpty {
        return /* create from history */
    }
    
    // Use category-based defaults
    let defaultCount = getDefaultSetCount(for: exercise)
    return (1...defaultCount).map { /* create empty set */ }
}

private func getDefaultSetCount(for exercise: Exercise) -> Int {
    // Check explicit override first
    if let explicit = exercise.typicalSetCount {
        return explicit
    }
    
    // Category-based defaults
    switch exercise.category {
    case "Chest", "Back", "Legs": return 4
    case "Arms", "Shoulders": return 3
    case "Core", "Warmup": return 2
    case "Cardio": return 1
    default: return 3
    }
}
```

### Complexity: Medium
- Requires category-to-setcount mapping
- Optional per-exercise overrides
- Needs thoughtful defaults

### User Benefit: Medium
- More accurate defaults
- Respects training conventions
- Reduces need for user configuration

---

## Enhancement 8: Set Count Learning & Patterns

### Problem Statement

Over time, users develop consistent patterns (e.g., always do 4 sets of bench press, but 3 sets of curls). The system could learn these patterns automatically.

### Proposed Solution

Track average set counts per exercise over last N workouts and use that as the default.

### Implementation

**In ViewModel:**
```swift
private func getTypicalSetCount(for exercise: Exercise) -> Int {
    // Analyze last 5-10 workouts for this exercise
    let recentWorkouts = getRecentWorkouts(for: exercise, limit: 10)
    let setCounts = recentWorkouts.map { $0.getSets().count }
    
    if setCounts.isEmpty {
        return 3 // Fallback
    }
    
    // Use mode (most common) or average
    let mode = setCounts.mostCommon()
    return mode ?? setCounts.average()
}
```

**Analytics Display:**
```
"You typically do 4 sets of Bench Press"
```

### Complexity: High
- Requires statistical analysis
- Need to define "typical" (mode, median, average?)
- Risk of overfitting to recent patterns
- Should blend with other defaults

### User Benefit: High
- Zero-configuration personalization
- Learns user preferences automatically
- More accurate over time

---

## Enhancement 9: Rest Time Pre-filling

### Problem Statement

Different exercises need different rest periods (heavy compounds need 3-5 min, accessories 60-90 sec). Currently, rest timer uses global default.

### Proposed Solution

Track typical rest times per exercise and pre-fill the rest timer accordingly.

### Implementation

**In SetRecord:**
```swift
struct SetRecord {
    // ... existing properties ...
    var restTimeAfter: TimeInterval? // NEW: Track rest taken
}
```

**When Set Completed:**
```swift
// Track rest time between sets
let lastCompletedTime = previousSet.completedAt
let currentCompletedTime = Date()
let restTaken = currentCompletedTime.timeIntervalSince(lastCompletedTime)

currentSet.restTimeAfter = restTaken
```

**Smart Rest Timer:**
```swift
func getRecommendedRestTime(for exercise: Exercise) -> TimeInterval {
    let lastSets = getLastSessionSets(for: exercise)
    let restTimes = lastSets.compactMap { $0.restTimeAfter }
    
    if !restTimes.isEmpty {
        return restTimes.average()
    }
    
    // Category-based fallback
    switch exercise.category {
    case "Chest", "Back", "Legs": return 180 // 3 min
    case "Arms", "Shoulders": return 90 // 90 sec
    default: return 90
    }
}
```

### Complexity: High
- Requires tracking rest times (new data point)
- Need to calculate intervals between sets
- Analysis across workouts
- Integration with rest timer

### User Benefit: Medium
- More accurate rest recommendations
- Adapts to user's actual recovery needs
- Passive tracking (no user input)

---

## Enhancement 10: Equipment Variation Handling

### Problem Statement

Users might do the same exercise with different equipment (barbell bench vs. dumbbell bench, or using different machines). Historical data from one variation might not apply to another.

### Proposed Solution

Track equipment used per set and filter history based on current equipment selection.

### Implementation

**Enhanced History Query:**
```swift
func getLastSessionSets(for exercise: Exercise, equipment: String?) -> [SetRecord] {
    let descriptor = FetchDescriptor<Workout>(
        predicate: #Predicate<Workout> { workout in
            workout.completedAt != nil
        },
        sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    
    do {
        let workouts = try modelContext.fetch(descriptor)
        
        for workout in workouts {
            guard let entries = workout.entries else { continue }
            
            let matchingEntries = entries.filter { entry in
                guard let entryExercise = entry.exercise else { return false }
                let exerciseMatches = entryExercise.id == exercise.id
                
                // NEW: Filter by equipment if specified
                if let targetEquipment = equipment {
                    let sets = entry.getSets()
                    let hasMatchingEquipment = sets.contains { $0.equipment == targetEquipment }
                    return exerciseMatches && hasMatchingEquipment
                }
                
                return exerciseMatches
            }
            
            if !matchingEntries.isEmpty {
                // Return sets filtered by equipment
            }
        }
    }
    
    return []
}
```

**UI Enhancement:**
- Equipment picker when adding exercise
- Filter history based on selection
- Show different PRs per equipment variant

### Complexity: High
- Requires equipment tracking per set (already exists in SetRecord)
- Need UI for equipment selection during add
- History queries become more complex
- Multiple PR tracking per exercise

### User Benefit: High
- More accurate historical data
- Prevents confusion (dumbbell vs. barbell weights)
- Better for users who regularly vary equipment

---

## Enhancement 11: Warm-up Set Auto-Generation

### Problem Statement

Many compound exercises require warm-up sets with progressively increasing weights. Users must manually create and calculate these.

### Proposed Solution

Detect first set as working weight and auto-generate 2-3 warm-up sets with calculated weights.

### Implementation

**Warm-up Calculation:**
```swift
func generateWarmupSets(targetWeight: Double, targetReps: Int) -> [SetRecord] {
    let bar = 45.0 // Empty barbell
    
    // Common warm-up progression: 40%, 60%, 80% of working weight
    let warmupPercentages = [0.4, 0.6, 0.8]
    
    return warmupPercentages.enumerated().map { index, percentage in
        let warmupWeight = max(bar, targetWeight * percentage)
        let warmupReps = targetReps + 2 // Slightly higher reps for warmup
        
        return SetRecord(
            setNumber: index + 1,
            reps: warmupReps,
            weight: warmupWeight,
            isCompleted: false,
            label: .warmup
        )
    }
}
```

**UI Option:**
- Button "Add Warm-up Sets" in exercise menu
- Auto-generate based on first set's weight
- User can adjust percentages in settings

### Complexity: Medium
- Need to insert sets before working sets
- Calculate appropriate percentages
- Handle different equipment (dumbbells scale differently)
- Renumber existing sets

### User Benefit: High
- Huge time-saver for compound lifts
- Reduces injury risk (proper warm-up)
- Educates users on warm-up protocols

---

## Enhancement 12: Voice Input Integration

### Problem Statement

During workouts, hands are often busy or sweaty. Typing weights and reps can be cumbersome.

### Proposed Solution

Allow voice input for setting weights and marking sets complete.

### Implementation

**Voice Commands:**
- "135 by 8" → Set weight to 135 lbs, reps to 8
- "Done" → Mark set complete
- "Add 5 pounds" → Increment weight by 5
- "Skip" → Skip current set

**iOS Integration:**
```swift
import Speech

struct SetRowView: View {
    @State private var isListening = false
    private let speechRecognizer = SFSpeechRecognizer()
    
    // Microphone button
    Button {
        startListening()
    } label: {
        Image(systemName: "mic.fill")
    }
}
```

### Complexity: Very High
- Requires Speech framework integration
- Need to parse natural language
- Handle permissions and errors
- Background listening considerations
- Privacy concerns

### User Benefit: High
- Significantly faster data entry
- Better hygiene (less phone touching)
- Accessibility improvement
- Feels futuristic

---

## Enhancement 13: Social Comparison & Suggestions

### Problem Statement

Users working out alone might not know if their weights are reasonable for their experience level.

### Proposed Solution

Anonymous aggregated data showing typical weight ranges for exercises based on experience level.

**Example Display:**
```
Your weight: 135 lbs
Typical for your level: 115-145 lbs
Top 10%: 165+ lbs
```

### Implementation

**Anonymous Analytics:**
- Opt-in data collection
- Aggregate by age, gender, experience level
- Show percentile rankings
- Privacy-focused (no individual data shared)

### Complexity: Very High
- Requires backend/cloud infrastructure
- Privacy and data protection
- User authentication
- Statistical analysis
- Ongoing maintenance

### User Benefit: Medium
- Motivational for some users
- Helps set realistic goals
- May cause comparison anxiety for others
- Not core to workout tracking

---

## Enhancement 14: Superset & Circuit Support

### Problem Statement

Users doing supersets or circuits currently must log exercises separately, losing the relationship between them.

### Proposed Solution

Allow grouping exercises as supersets, affecting rest timers and navigation.

### Implementation

**In WorkoutEntry:**
```swift
@Model
final class WorkoutEntry {
    // ... existing properties ...
    var supersetGroup: Int? // NEW: Group ID for supersets
}
```

**Behavior:**
- Exercises with same supersetGroup displayed together
- Completing set in exercise A advances to exercise B (not A set 2)
- Rest timer starts after all exercises in group complete
- Visual grouping in UI

### Complexity: High
- Requires entry grouping
- Complex UI changes
- Navigation logic updates
- Rest timer integration

### User Benefit: High for advanced users
- Critical for HIIT/circuit training
- Better represents actual workout structure
- Accurate rest tracking

---

## Enhancement 15: Export & Analysis

### Problem Statement

Users might want to analyze their workout data outside the app or share with coaches.

### Proposed Solution

Export workout history as CSV, JSON, or PDF for external analysis.

### Implementation

**Export Options:**
- CSV: Exercise, Date, Weight, Reps, Volume
- JSON: Full workout data structure
- PDF: Formatted workout log with charts

**File Export:**
```swift
func exportWorkoutHistory() -> URL {
    let workouts = fetchAllWorkouts()
    let csvData = convertToCSV(workouts)
    
    // Write to file
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("workouts.csv")
    try? csvData.write(to: fileURL)
    
    return fileURL
}
```

### Complexity: Medium
- CSV generation relatively simple
- PDF requires formatting library
- Share sheet integration
- Consider data privacy

### User Benefit: Medium
- Useful for data-driven users
- Required for coaching relationships
- Enables external analysis tools
- Good for backups

---

## Implementation Priority Matrix

| Enhancement | Complexity | User Benefit | Priority |
|-------------|-----------|--------------|----------|
| Quick Adjust Controls (#5) | Low | High | **High** |
| Time-Based Relevance (#3) | Low | Medium | **High** |
| User Preference for Set Count (#6) | Low | Medium | **High** |
| Visual History Indicators (#4) | Medium | High | **Medium** |
| Template Integration (#1) | Medium | Medium | **Medium** |
| Exercise-Type Awareness (#7) | Medium | Medium | **Medium** |
| Warm-up Auto-Generation (#11) | Medium | High | **Medium** |
| Export & Analysis (#15) | Medium | Medium | **Medium** |
| Progressive Overload Auto-Increment (#2) | High | High | **Low** |
| Set Count Learning (#8) | High | High | **Low** |
| Equipment Variation (#10) | High | High | **Low** |
| Rest Time Pre-filling (#9) | High | Medium | **Low** |
| Superset Support (#14) | High | High | **Low** |
| Voice Input (#12) | Very High | High | **Very Low** |
| Social Comparison (#13) | Very High | Medium | **Very Low** |

---

## Recommended Implementation Order

**Phase 1: Quick Wins** (Low complexity, high impact)
1. Quick adjust controls (+/- buttons)
2. Time-based relevance filtering
3. User preference for default set count

**Phase 2: Enhanced Intelligence** (Medium complexity)
4. Visual history indicators
5. Template integration
6. Exercise-type awareness
7. Warm-up set generation

**Phase 3: Advanced Features** (High complexity)
8. Progressive overload auto-increment
9. Set count learning
10. Equipment variation handling
11. Rest time pre-filling

**Phase 4: Major Features** (Very high complexity)
12. Superset/circuit support
13. Export & analysis tools
14. Voice input integration
15. Social comparison (if desired)

---

## Success Metrics

For each enhancement, measure:
- **Adoption Rate**: % of users who use the feature
- **Time Savings**: Reduction in workout logging time
- **Accuracy**: How often pre-filled values are kept vs. changed
- **User Satisfaction**: Feedback and ratings
- **Retention**: Impact on user engagement

---

## Conclusion

The smart default sets feature has a strong foundation. These enhancements can be implemented iteratively based on user feedback and resource availability. Start with quick wins (#5, #3, #6) to validate the approach, then move to more complex features as data and user needs indicate.

**Key Principles:**
- User control always takes precedence over automation
- Start simple, add complexity only when needed
- Measure impact before investing in complex features
- Privacy and data protection are non-negotiable

---

**Related Documentation:**
- [FEATURES.md](../../development/FEATURES.md) - Current feature documentation
- [AUTO_POPULATE_EXERCISE_SETS.md](./AUTO_POPULATE_EXERCISE_SETS.md) - Original feature spec
- [MODELS.md](../MODELS.md) - Data model documentation
