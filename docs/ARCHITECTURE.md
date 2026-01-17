# Architecture

## Tech Stack

- **SwiftUI**: Modern declarative UI framework for iOS
- **SwiftData**: Apple's persistence framework (replaces Core Data)
- **MVVM Pattern**: Model-View-ViewModel architecture for separation of concerns
- **Combine**: Reactive programming for state management
- **Target**: iOS 17.0+ (uses SwiftData which requires iOS 17+)

## Folder Structure

```
FlowState/
├── Models/              # SwiftData models and data structures
│   ├── Exercise.swift            # Exercise entity with categories
│   ├── SetRecord.swift           # Codable struct (stored as JSON)
│   ├── Workout.swift             # Workout entity
│   ├── WorkoutEntry.swift        # Junction between Workout and Exercise
│   ├── WorkoutTemplate.swift     # Template for quick workout creation
│   └── TemplateExercise.swift    # Exercise configuration in templates
│
├── ViewModels/          # Business logic and state management
│   ├── WorkoutStateManager.swift    # @EnvironmentObject for app-wide state
│   ├── ActiveWorkoutViewModel.swift # Active workout operations
│   ├── HistoryViewModel.swift       # Completed workout queries
│   ├── TemplateViewModel.swift      # Template CRUD operations
│   ├── ExerciseLibraryViewModel.swift # Exercise library management
│   └── RestTimerViewModel.swift     # Rest timer logic
│
├── Views/               # SwiftUI views
│   ├── ContentView.swift                # Root view with TabView
│   ├── HomeView.swift                   # Home dashboard
│   ├── ActiveWorkoutView.swift          # Active workout UI (non-fullscreen)
│   ├── ActiveWorkoutFullScreenView.swift # Full-screen workout mode
│   ├── FloatingWorkoutPill.swift        # Minimized workout indicator
│   ├── HistoryView.swift                # Workout history list
│   ├── WorkoutHistoryDetailView.swift   # Individual workout details
│   ├── ExerciseListView.swift           # Exercise library
│   ├── TemplateListView.swift           # Template list
│   ├── TemplateDetailView.swift         # Template editing
│   ├── CreateTemplateView.swift         # Template creation
│   ├── RestTimerView.swift              # Rest timer UI
│   ├── SetRowView.swift                 # Individual set input row
│   ├── CustomNumPadView.swift           # Custom number pad component
│   ├── LabelPickerSheet.swift           # Set label selection sheet
│   └── [Various sheet views]            # Modals for adding/editing
│
├── FlowStateApp.swift   # App entry point with ModelContainer setup
└── Assets.xcassets/     # App icons and colors
```

## Key Architectural Decisions

### Why SwiftData?

- **Modern API**: Simpler than Core Data, more Swift-native
- **Type Safety**: Leverages Swift's type system
- **Declarative**: `@Model` macro makes models concise
- **Relationships**: Built-in relationship management
- **iOS 17+**: Aligns with minimum deployment target

### Why MVVM?

- **Separation of Concerns**: Views are declarative, ViewModels handle logic
- **Testability**: Business logic isolated from UI
- **Reusability**: ViewModels can be shared across views
- **State Management**: `@Published` properties enable reactive UI updates

### Why SetRecord as JSON?

`SetRecord` is a `Codable` struct, not a SwiftData model, stored as JSON in `WorkoutEntry.setsData`:

- **Flexibility**: Sets vary per exercise type (weight/reps, duration, distance)
- **Performance**: Arrays of structs encoded once vs. multiple SwiftData relationships
- **Simplicity**: No need for separate SetRecord model with inverse relationships
- **Migration**: Easier to change set structure without database migrations

### EnvironmentObject Pattern

`WorkoutStateManager` is an `@EnvironmentObject` because:

- **App-Wide State**: Active workout state needed across multiple views
- **Single Source of Truth**: Prevents state duplication
- **Deep Injection**: Automatically available to child views without prop drilling
- **Lifecycle Management**: Survives view rebuilds and navigation

## Data Flow

### Starting a Workout

1. User selects template or starts empty workout in `HomeView`
2. `HomeView` calls `ActiveWorkoutViewModel.startWorkoutFromTemplate()` or `startEmptyWorkout()`
3. ViewModel creates `Workout` entity with `completedAt = nil`
4. If from template, copies `TemplateExercise` → `WorkoutEntry` with default sets
5. ViewModel saves to SwiftData `ModelContext`
6. `WorkoutStateManager.setActiveWorkout()` updates app-wide state
7. `ContentView` shows full-screen workout via `fullScreenCover`

### Logging Sets

1. User edits set in `SetRowView` (weight/reps/completion)
2. `SetRowView` calls `ActiveWorkoutViewModel.updateSet()`
3. ViewModel:
   - Retrieves sets via `WorkoutEntry.getSets()` (decodes JSON)
   - Updates `SetRecord` in array
   - Saves back via `WorkoutEntry.setSets()` (encodes JSON)
   - Persists to SwiftData
4. If set marked complete, rest timer auto-starts via `WorkoutStateManager`

### Completing Workout

1. User taps "Finish Workout" in `ActiveWorkoutView`
2. `ActiveWorkoutViewModel.finishWorkout()` sets `workout.completedAt = Date()`
3. ViewModel saves to SwiftData
4. `WorkoutStateManager.finishWorkout()` clears active workout state
5. Full-screen workout dismisses, user returns to `HomeView`
6. `HistoryView` can now query this workout (filtered by `completedAt != nil`)

### State Synchronization

- `WorkoutStateManager` maintains app-wide active workout state
- `ActiveWorkoutViewModel` manages workout operations (CRUD)
- Timer updates use `Timer.scheduledTimer` in both ViewModels
- SwiftData changes propagate via `@Published` properties
- Views observe ViewModels via `@ObservedObject` or `@StateObject`

## Key Patterns

### Single Active Workout Enforcement

- Only one workout can have `completedAt == nil` at a time
- Starting new workout checks `hasActiveWorkout()` first
- User can discard existing workout via alert

### Workout Minimization

- Full-screen workout: `isWorkoutFullScreen = true` (fullScreenCover)
- Minimized: `isWorkoutFullScreen = false` (shows FloatingWorkoutPill)
- Timer continues running in both states
- Floating pill shows elapsed time and allows quick return to full-screen

### Rest Timer Integration

- Auto-starts when set is marked complete (if not already running)
- `RestTimerViewModel` manages countdown logic
- Circular progress indicator with skip/+30s/-30s controls
- Stops when new set is started or workout is finished/cancelled

### Custom Input Components

- `CustomNumPadView` replaces native keyboard for better UX during workouts
- Built-in "Done" button eliminates keyboard dismissal friction
- Supports different input types (decimal weights, whole number reps)
- Consistent styling and behavior across the app
- Used for weight/reps input and exercise notes

## Persistence

- SwiftData automatically persists to device storage
- Model schema defined in `FlowStateApp.swift` with `Schema()`
- Models include: `Exercise`, `Workout`, `WorkoutEntry`, `WorkoutTemplate`, `TemplateExercise`
- No manual migration needed for schema changes (SwiftData handles it)
