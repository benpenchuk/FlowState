# ViewModels

All ViewModels in the app, their responsibilities, and usage.

## WorkoutStateManager

**Location:** `ViewModels/WorkoutStateManager.swift`

**Type:** `@EnvironmentObject` (app-wide singleton)

**Responsibility:** Manages app-wide workout state and coordination

**Properties:**
- `@Published var activeWorkout: Workout?` - Currently active workout
- `@Published var isWorkoutFullScreen: Bool` - Whether workout is in full-screen mode
- `@Published var elapsedTime: TimeInterval` - Elapsed time for active workout
- `@Published var restTimerViewModel: RestTimerViewModel` - Rest timer state

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize with SwiftData context
- `loadActiveWorkout()` - Load active workout from SwiftData (completedAt == nil)
- `refreshActiveWorkout()` - Reload active workout state
- `hasActiveWorkout() -> Bool` - Check if workout is active
- `setActiveWorkout(_ workout: Workout)` - Set active workout and start timer
- `showWorkoutFullScreen()` - Enter full-screen mode
- `minimizeWorkout()` - Exit full-screen mode (shows floating pill)
- `finishWorkout()` - Mark workout as completed
- `cancelWorkout()` - Delete active workout
- `startRestTimer(duration: Int?)` - Start rest timer
- `stopRestTimer()` - Stop rest timer

**Used By:**
- `ContentView` - Root view for app state
- `HomeView` - Check active workout before starting new
- `ActiveWorkoutFullScreenView` - Full-screen workout state
- `FloatingWorkoutPill` - Minimized workout display

**Special Notes:**
- Must be initialized in `FlowStateApp.swift` and injected as `@EnvironmentObject`
- Uses `Timer` to update `elapsedTime` every second
- Coordinates between `ActiveWorkoutViewModel` and rest timer
- Handles single active workout enforcement

---

## ActiveWorkoutViewModel

**Location:** `ViewModels/ActiveWorkoutViewModel.swift`

**Type:** `@StateObject` or `@ObservedObject` (view-scoped)

**Responsibility:** Manages active workout operations (CRUD for sets, exercises)

**Properties:**
- `@Published var activeWorkout: Workout?` - Current active workout
- `@Published var elapsedTime: TimeInterval` - Elapsed time (duplicate of WorkoutStateManager)

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize with SwiftData context
- `refreshActiveWorkout()` - Reload active workout
- `loadActiveWorkout()` - Query for workout with completedAt == nil
- `hasActiveWorkout() -> Bool` - Check if workout exists
- `startWorkoutFromTemplate(_ template: WorkoutTemplate, discardExisting: Bool)` - Create workout from template
- `startEmptyWorkout(name: String?, discardExisting: Bool)` - Create empty workout
- `addExerciseToWorkout(_ exercise: Exercise)` - Add exercise to active workout
- `addSetToEntry(_ entry: WorkoutEntry)` - Add set to exercise
- `updateSet(in entry: WorkoutEntry, set: SetRecord, reps: Int?, weight: Double?, isCompleted: Bool)` - Update set data
- `removeSet(from entry: WorkoutEntry, set: SetRecord)` - Delete set
- `finishWorkout()` - Mark workout as completed (sets completedAt)
- `cancelWorkout()` - Delete workout

**Used By:**
- `ActiveWorkoutView` - All workout operations
- `HomeView` - Starting workouts
- `ActiveWorkoutFullScreenView` - Wraps ActiveWorkoutView

**Special Notes:**
- Handles SetRecord encoding/decoding via `WorkoutEntry.getSets()` / `setSets()`
- Pre-populates sets from template defaults
- Manages set numbering (renumbers after deletion)
- Coordinates with `WorkoutStateManager` for state updates

---

## HistoryViewModel

**Location:** `ViewModels/HistoryViewModel.swift`

**Type:** `@StateObject` (view-scoped)

**Responsibility:** Manages completed workout queries and calculations

**Properties:**
- `@Published var completedWorkouts: [Workout]` - All completed workouts

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize with SwiftData context
- `fetchCompletedWorkouts()` - Query workouts with completedAt != nil
- `deleteWorkout(_ workout: Workout)` - Delete completed workout
- `groupWorkoutsByDate() -> [(String, [Workout])]` - Group workouts by date (Today, Yesterday, etc.)
- `calculateDuration(startedAt: Date, completedAt: Date) -> TimeInterval` - Calculate workout duration
- `formatDuration(_ duration: TimeInterval) -> String` - Format duration as "Xh Ymin" or "Y min"
- `countCompletedSets(in workout: Workout) -> Int` - Count completed sets in workout

**Used By:**
- `HistoryView` - Display workout list
- `WorkoutHistoryDetailView` - Show workout details

**Special Notes:**
- Only queries completed workouts (completedAt != nil)
- Date grouping logic: Today, Yesterday, Last 7 days (day names), then months
- Helper methods for formatting workout statistics

---

## TemplateViewModel

**Location:** `ViewModels/TemplateViewModel.swift`

**Type:** `@StateObject` or `@ObservedObject` (view-scoped)

**Responsibility:** Manages workout template CRUD operations

**Properties:**
- `@Published var templates: [WorkoutTemplate]` - All templates

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize with SwiftData context
- `fetchAllTemplates()` - Query all templates, sorted by lastUsedAt (then createdAt)
- `createTemplate(name: String, exercises: [(Exercise, defaultSets: Int, defaultReps: Int, defaultWeight: Double?)])` - Create new template
- `updateTemplate(_ template: WorkoutTemplate)` - Save template changes
- `updateTemplateExercises(_ template: WorkoutTemplate, exercises: [TemplateExercise])` - Update exercises in template
- `deleteTemplate(_ template: WorkoutTemplate)` - Delete template
- `markTemplateUsed(_ template: WorkoutTemplate)` - Update lastUsedAt timestamp

**Used By:**
- `TemplateListView` - Template list
- `TemplateDetailView` - Edit template
- `CreateTemplateView` - Create template
- `HomeView` - Display recent templates

**Special Notes:**
- Handles exercise reordering via `updateTemplateExercises()`
- Sorts templates by lastUsedAt first, then createdAt
- Cascade delete handled by SwiftData relationships

---

## ExerciseLibraryViewModel

**Location:** `ViewModels/ExerciseLibraryViewModel.swift`

**Type:** `@StateObject` (view-scoped)

**Responsibility:** Manages exercise library and custom exercises

**Properties:**
- `@Published var exercises: [Exercise]` - All exercises
- `@Published var searchText: String` - Search query

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize and seed defaults
- `loadAllExercises()` - Query all exercises, sorted by category then name
- `addCustomExercise(name: String, category: ExerciseCategory)` - Create custom exercise
- `deleteCustomExercise(_ exercise: Exercise)` - Delete custom exercise (only if isCustom == true)
- `seedDefaultExercisesIfNeeded()` - Insert default exercises on first launch

**Computed Properties:**
- `filteredExercises: [Exercise]` - Exercises filtered by searchText
- `exercisesByCategory: [ExerciseCategory: [Exercise]]` - Exercises grouped by category
- `sortedCategories: [ExerciseCategory]` - Categories sorted alphabetically

**Used By:**
- `ExerciseListView` - Exercise library UI

**Special Notes:**
- Seeds ~40 default exercises on first launch (if library is empty)
- Only allows deletion of custom exercises (not defaults)
- Search is case-insensitive
- Exercises sorted by category, then alphabetically within category

---

## RestTimerViewModel

**Location:** `ViewModels/RestTimerViewModel.swift`

**Type:** `@Published` property in `WorkoutStateManager`

**Responsibility:** Manages rest timer countdown logic

**Properties:**
- `@Published var isRunning: Bool` - Whether timer is active
- `@Published var timeRemaining: TimeInterval` - Seconds remaining
- `@Published var totalDuration: TimeInterval` - Total timer duration

**Key Methods:**
- `init(defaultDuration: Int)` - Initialize with default duration (seconds)
- `start(duration: Int?)` - Start timer (uses duration or default)
- `stop()` - Stop timer
- `addTime(_ seconds: Int)` - Add time to timer
- `subtractTime(_ seconds: Int)` - Remove time from timer
- `skip()` - Stop timer immediately

**Used By:**
- `WorkoutStateManager` - Integrated rest timer
- `RestTimerView` - Timer UI

**Special Notes:**
- Timer updates every second via `Timer`
- Auto-starts when set is marked complete
- Stops when workout finishes or new set is logged

---

## ProgressViewModel

**Location:** `ViewModels/ProgressViewModel.swift`

**Type:** `@StateObject` (view-scoped)

**Responsibility:** Manages progress tracking, PR detection, and exercise history

**Properties:**
- `@Published var recentPRs: [PersonalRecord]` - Recent PRs (last 7 days)

**Key Methods:**
- `setModelContext(_ context: ModelContext)` - Initialize with SwiftData context
- `getAllCompletedSets(for exercise: Exercise) -> [(SetRecord, Date)]` - Get all completed sets for an exercise
- `calculatePR(for exercise: Exercise) -> PersonalRecord?` - Get current PR for exercise
- `calculatePRFromSets(for exercise: Exercise) -> (weight: Double, reps: Int, date: Date)?` - Calculate PR on-the-fly
- `detectNewPR(exercise:weight:reps:workout:) -> PersonalRecord?` - Detect and save new PR
- `getRecentPRs(days: Int) -> [PersonalRecord]` - Get recent PRs (default 7 days)
- `getExerciseHistory(for exercise: Exercise, limit: Int) -> [(date: Date, maxWeight: Double, sets: [SetRecord])]` - Get exercise history
- `getWeightProgression(for exercise: Exercise) -> [(date: Date, weight: Double)]` - Get data for progress chart

**Used By:**
- `ActiveWorkoutViewModel` - PR detection when sets are completed
- `ExerciseDetailView` - Progress tracking and history
- `HomeView` - Recent PRs display

**Special Notes:**
- PRs are stored in SwiftData for performance
- PR detection compares weight only (highest weight for at least 1 rep)
- Automatically creates PersonalRecord when new PR is detected
- Chart data sorted by date ascending for proper visualization

---

## ViewModel Usage Patterns

### @EnvironmentObject Pattern
- **WorkoutStateManager**: App-wide state, injected once at app root

### @StateObject Pattern
- Used in views that create and own the ViewModel
- Examples: `HomeView` (TemplateViewModel, ActiveWorkoutViewModel, ProgressViewModel)
- Examples: `HistoryView` (HistoryViewModel)
- Examples: `ExerciseListView` (ExerciseLibraryViewModel)
- Examples: `ExerciseDetailView` (ProgressViewModel)

### @ObservedObject Pattern
- Used when ViewModel is passed from parent
- Examples: `ActiveWorkoutView` (receives ActiveWorkoutViewModel)
- Examples: `WorkoutHistoryDetailView` (receives HistoryViewModel)

### ModelContext Injection
- All ViewModels require `ModelContext` via `setModelContext(_:)`
- Called in view `.onAppear` or `.init`
- ViewModels don't hold strong reference to context (avoid retain cycles)

### Data Flow Pattern
1. View creates/observes ViewModel
2. View calls `viewModel.setModelContext(modelContext)` 
3. ViewModel queries SwiftData
4. ViewModel updates `@Published` properties
5. View automatically re-renders

### Error Handling
- ViewModels use `print()` for errors (no UI error handling yet)
- Failed operations silently fail (no user feedback)
- Database operations wrapped in `do-catch` blocks

---

## ViewModel Dependencies

```
WorkoutStateManager (EnvironmentObject)
├── RestTimerViewModel (embedded)
└── Coordinates with ActiveWorkoutViewModel

ActiveWorkoutViewModel
└── Uses WorkoutStateManager (not directly, via Workout model)

HistoryViewModel
└── Independent (queries completed workouts)

TemplateViewModel
└── Independent (manages templates)

ExerciseLibraryViewModel
└── Independent (manages exercises)

ProgressViewModel
├── Used by ActiveWorkoutViewModel (PR detection)
├── Used by ExerciseDetailView (progress tracking)
└── Used by HomeView (recent PRs)
```
