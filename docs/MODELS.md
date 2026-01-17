# Data Models

## SwiftData Models

### Exercise

Represents a single exercise in the library. Supports both strength training and cardio exercises.

**Properties:**
- `id: UUID` - Unique identifier
- `name: String` - Exercise name (e.g., "Bench Press")
- `exerciseType: ExerciseType` - Type of exercise (.strength or .cardio)
- `category: String` - Category name (e.g., "Chest", "Back", "Running", "Cycling")
- `equipment: [Equipment]` - Array of equipment options for this exercise
- `primaryMuscles: [String]` - Primary muscles worked (for strength exercises)
- `secondaryMuscles: [String]` - Secondary muscles worked (for strength exercises)
- `instructions: ExerciseInstructions` - Structured instructions (setup, execution, tips)
- `isCustom: Bool` - Whether user created this exercise (vs. pre-built)
- `isFavorite: Bool` - Whether exercise is favorited by user
- `createdAt: Date` - When exercise was created

**Relationships:**
- `templateExercises: [TemplateExercise]?` - Exercises using this in templates
- `workoutEntries: [WorkoutEntry]?` - Workout entries using this exercise

**Usage:**
- Stored in exercise library
- Referenced by templates and workout entries
- Can be created by user or pre-populated
- Comprehensive library seeded with ~80+ exercises including instructions

---

### WorkoutTemplate

A reusable template for creating workouts quickly.

**Properties:**
- `id: UUID` - Unique identifier
- `name: String` - Template name (e.g., "Push Day")
- `createdAt: Date` - When template was created
- `lastUsedAt: Date?` - Last time template was used to start workout

**Relationships:**
- `exercises: [TemplateExercise]?` - Exercises in this template (ordered)

**Usage:**
- Created in `CreateTemplateView`
- Displayed on `HomeView` for quick start
- Copied into `Workout` when starting new workout

---

### TemplateExercise

Configuration for an exercise within a template.

**Properties:**
- `id: UUID` - Unique identifier
- `order: Int` - Order in template (0-based)
- `defaultSets: Int` - Default number of sets
- `defaultReps: Int` - Default reps per set
- `defaultWeight: Double?` - Default weight (nil if bodyweight)

**Relationships:**
- `exercise: Exercise?` - Reference to Exercise model
- `template: WorkoutTemplate?` - Reference to template

**Usage:**
- Defines default sets/reps/weight when template is used
- User can override defaults during workout

---

### Workout

Represents a single workout session (active or completed).

**Properties:**
- `id: UUID` - Unique identifier
- `name: String?` - Optional workout name
- `startedAt: Date` - When workout started
- `completedAt: Date?` - When workout finished (nil = active workout)
- `notes: String?` - Optional notes about the workout
- `effortRating: Int?` - Optional effort rating (1-10 scale)
- `totalRestTime: TimeInterval?` - Sum of all rest periods during the workout

**Relationships:**
- `entries: [WorkoutEntry]?` - Exercises in this workout (ordered)

**Usage:**
- Active workout: `completedAt == nil`
- Completed workout: `completedAt != nil` (appears in history)
- Only one active workout allowed at a time
- `effortRating` and `notes` are captured via `WorkoutCompletionView` when finishing workout
- `totalRestTime` is automatically tracked and accumulated during the workout

---

### WorkoutEntry

Junction between Workout and Exercise. Represents one exercise in a workout.

**Properties:**
- `id: UUID` - Unique identifier
- `order: Int` - Order in workout (0-based)
- `setsData: Data?` - JSON-encoded `[SetRecord]` array
- `notes: String?` - Optional per-exercise notes during workout
- `isExpanded: Bool` - Whether exercise is expanded in workout view (default: true)

**Relationships:**
- `exercise: Exercise?` - Reference to Exercise model
- `workout: Workout?` - Reference to Workout model

**Helper Methods:**
- `getSets() -> [SetRecord]` - Decodes `setsData` to array
- `setSets(_ sets: [SetRecord])` - Encodes array to `setsData`

**Usage:**
- Created when adding exercise to workout
- Stores all sets for that exercise in this workout
- Stores per-exercise notes (separate from workout-level notes)
- Tracks expansion state for UI (expand/collapse exercises)
- Sets stored as JSON, not SwiftData relationships

---

### PersonalRecord

Represents a personal record (PR) for an exercise - the highest weight lifted for at least 1 rep.

**Properties:**
- `id: UUID` - Unique identifier
- `weight: Double` - Weight lifted (lbs/kg)
- `reps: Int` - Number of repetitions
- `achievedAt: Date` - When the PR was achieved

**Relationships:**
- `exercise: Exercise?` - Reference to Exercise model
- `workout: Workout?` - Reference to Workout where PR was achieved (optional)

**Usage:**
- Automatically created when a set is completed that exceeds previous PR
- Used for progress tracking and charts
- Displayed on Home dashboard and exercise detail views

---

### UserProfile

Represents the user's profile and preferences. Only one instance exists per app.

**Properties:**
- `id: UUID` - Unique identifier
- `name: String` - User's name (default: "Athlete")
- `createdAt: Date` - When profile was created (first app launch)
- `preferredUnits: String` - Units preference (stored as String, accessed via `units` computed property)
- `defaultRestTime: Int` - Default rest timer duration in seconds (default: 90)
- `appearanceMode: String` - Appearance preference (stored as String, accessed via `appearance` computed property)

**Computed Properties:**
- `units: Units` - Get/set preferred units (.lbs or .kg)
- `appearance: AppearanceMode` - Get/set appearance mode (.dark, .light, or .system)

**Usage:**
- Single instance model (only one profile per app)
- Created automatically on first launch
- Used throughout app for units conversion and appearance preferences
- Default rest time used when starting rest timer

---

## Enums

### Units

Enum defining weight units.

**Values:**
- `lbs` - Pounds (default)
- `kg` - Kilograms

**Usage:**
- User preference for displaying weights
- All weights stored internally as lbs, converted for display only
- Conversion: 1 kg = 2.20462 lbs

---

### AppearanceMode

Enum defining appearance mode preference.

**Values:**
- `dark` - Force dark mode
- `light` - Force light mode
- `system` - Use device setting (default)

**Usage:**
- User preference for app appearance
- Applied via `.preferredColorScheme()` in ContentView

---

## Codable Structs (Not SwiftData Models)

### SetRecord

Represents a single set within a workout entry. Stored as JSON in `WorkoutEntry.setsData`.

**Properties:**
- `id: UUID` - Unique identifier for this set
- `setNumber: Int` - Set number (1, 2, 3, etc.)
- `reps: Int?` - Number of repetitions
- `weight: Double?` - Weight lifted (lbs/kg)
- `duration: TimeInterval?` - Duration for cardio sets (seconds)
- `distance: Double?` - Distance for cardio sets (miles/km)
- `equipment: String?` - Optional: which equipment was used this set
- `isCompleted: Bool` - Whether set was completed
- `completedAt: Date?` - When this set was marked complete (for analyzing workout pace)
- `label: String?` - Optional set label (Warmup, Failure, Drop Set, PR Attempt)

**Why Not a SwiftData Model?**

1. **Performance**: Arrays of structs encoded once vs. multiple SwiftData queries
2. **Flexibility**: Different exercise types need different fields (weight/reps vs. duration/distance)
3. **Simplicity**: No need for inverse relationships and cascade deletes
4. **Migration**: Easier to change structure without database schema changes

**Storage:**
- Entire `[SetRecord]` array encoded as JSON via `JSONEncoder`
- Stored in `WorkoutEntry.setsData: Data?`
- Decoded/encoded via helper methods on `WorkoutEntry`

---

### ExerciseType

Enum defining the type of exercise.

**Values:**
- `strength` - Strength training exercises (weight lifting, bodyweight)
- `cardio` - Cardiovascular exercises (running, cycling, etc.)

**Usage:**
- Filters exercises in library UI
- Determines which categories are available
- Affects how exercises are displayed and tracked

---

### Equipment

Enum defining available equipment options.

**Strength Equipment:**
- `barbell`, `dumbbell`, `cable`, `machine`, `bodyweight`, `kettlebell`, `resistanceBand`
- `ezBar`, `trapBar`, `smithMachine`, `pullupBar`, `dipBars`
- `bench`, `inclineBench`, `declineBench`

**Cardio Equipment:**
- `treadmill`, `bike`, `rowingMachine`, `elliptical`, `stairClimber`, `jumpRope`, `none`

**Usage:**
- Filters exercises by available equipment
- Displayed as tags on exercise rows
- Helps users find exercises they can perform

---

## Structs (Not SwiftData Models)

### ExerciseInstructions

Structured instructions for performing an exercise.

**Properties:**
- `setup: String` - 1-2 sentences on positioning and grip/stance
- `execution: String` - 2-3 sentences describing the movement
- `tips: String` - 1-2 practical cues for good form

**Usage:**
- Displayed in ExerciseDetailView
- Written in second person ("Grip the bar", "Lower the weight")
- Consistent format across all exercises

---

## Relationship Diagram

```
WorkoutTemplate
    │
    ├──> TemplateExercise (many)
    │       │
    │       └──> Exercise (one)
    │
    └──> [When starting workout]
            │
            └──> Workout (created)
                    │
                    └──> WorkoutEntry (many)
                            │
                            ├──> Exercise (one)
                            │
                            └──> setsData: Data
                                    └──> [SetRecord] (JSON array)
```

**Key Relationships:**

1. **Template → Exercise**: Many-to-many via `TemplateExercise`
2. **Workout → Exercise**: Many-to-many via `WorkoutEntry`
3. **Exercise → PersonalRecord**: One-to-many (exercise can have multiple PRs over time)
4. **Sets**: Not relationships, stored as JSON in `WorkoutEntry.setsData`
5. **Delete Rules**: 
   - Deleting `Exercise` nullifies references (doesn't delete workouts or PRs)
   - Deleting `Workout` cascades to `WorkoutEntry`
   - Deleting `WorkoutTemplate` cascades to `TemplateExercise`
   - Deleting `Workout` nullifies PR references (PRs are preserved)

---

## Data Flow Example

**Starting workout from template:**

1. User selects "Push Day" template
2. `WorkoutTemplate` has 3 `TemplateExercise` entries
3. System creates new `Workout` with `completedAt = nil`
4. For each `TemplateExercise`:
   - Create `WorkoutEntry` with reference to `Exercise`
   - Create default `SetRecord` array with `defaultSets` count
   - Encode to JSON, store in `WorkoutEntry.setsData`
5. Workout is now active, user can log sets

**Logging a set:**

1. User edits weight in `SetRowView`
2. `ActiveWorkoutViewModel.updateSet()` called
3. Retrieve `[SetRecord]` via `WorkoutEntry.getSets()`
4. Find matching set by `id`, update `weight` property
5. Save back via `WorkoutEntry.setSets()`
6. SwiftData persists `WorkoutEntry` with updated `setsData`
