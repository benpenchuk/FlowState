# Views

All SwiftUI views in the app, organized by purpose.

## Root & Navigation

### ContentView.swift

**Description:** Root view containing TabView and managing workout state

**ViewModel:** None (uses `@EnvironmentObject workoutState: WorkoutStateManager`)

**Key Features:**
- TabView with Home, History, Exercises tabs
- Manages dark theme (`.preferredColorScheme(.dark)`)
- Conditionally shows `FloatingWorkoutPill` when workout is active but minimized
- Presents full-screen workout via `fullScreenCover` when `isWorkoutFullScreen = true`

**Presents:**
- `ActiveWorkoutFullScreenView` (fullScreenCover)

---

## Home & Dashboard

### HomeView.swift

**Description:** Home dashboard showing templates, recent PRs, and quick start options

**ViewModel:** 
- `@StateObject templateViewModel: TemplateViewModel`
- `@StateObject workoutViewModel: ActiveWorkoutViewModel`
- `@StateObject progressViewModel: ProgressViewModel`
- `@EnvironmentObject workoutState: WorkoutStateManager`

**Key Features:**
- Templates section with horizontal scrolling cards
- Recent PRs section (last 7 days)
- "See All" link to template list
- Quick start empty workout button
- Alerts for starting workouts (handles active workout conflicts)

**Contains:**
- `TemplateCardView` - Template cards
- `PRCardView` - PR display cards

**Presents:**
- `TemplateListView` (sheet)

**Navigation:**
- Embedded in ContentView TabView

---

## Workout Views

### ActiveWorkoutFullScreenView.swift

**Description:** Full-screen workout mode (takes over entire screen)

**ViewModel:** 
- `@EnvironmentObject workoutState: WorkoutStateManager`
- Creates `@StateObject activeWorkoutViewModel: ActiveWorkoutViewModel` internally

**Key Features:**
- Full-screen takeover UI
- Embedded `ActiveWorkoutView` for workout content
- Shows rest timer when active
- Can be dismissed to minimized state

**Contains:**
- `ActiveWorkoutView`

**Navigation:**
- Presented via `fullScreenCover` from `ContentView`

---

### ActiveWorkoutView.swift

**Description:** Main workout UI for logging sets and managing exercises

**ViewModel:** `@ObservedObject viewModel: ActiveWorkoutViewModel`

**Key Features:**
- Timer display (elapsed time)
- Editable workout name
- Exercise sections with sets
- Add exercise button
- Finish workout button
- Cancel workout option

**Contains:**
- `ExerciseSectionView` (multiple)
- `SetRowView` (within ExerciseSectionView)

**Presents:**
- `AddExerciseToWorkoutSheet` (sheet)

**Navigation:**
- Embedded in `ActiveWorkoutFullScreenView`

---

### FloatingWorkoutPill.swift

**Description:** Floating button showing elapsed time when workout is minimized

**ViewModel:** `@ObservedObject workoutState: WorkoutStateManager`

**Key Features:**
- Circular floating button
- Shows elapsed time (MM:SS format)
- Tap to return to full-screen workout
- Only visible when `activeWorkout != nil && !isWorkoutFullScreen`

**Navigation:**
- Overlaid on `ContentView` (zIndex: 1)

---

### RestTimerView.swift

**Description:** Rest timer UI with circular progress indicator

**ViewModel:** `@ObservedObject viewModel: RestTimerViewModel`

**Key Features:**
- Circular progress indicator
- Time remaining display
- +30s and -30s adjustment buttons
- Skip button

**Navigation:**
- Embedded in `ActiveWorkoutFullScreenView` (conditionally shown)

---

### SetRowView.swift

**Description:** Individual set input row (weight, reps, completion)

**ViewModel:** None (receives callbacks from parent)

**Key Features:**
- Set number display
- Weight input field (optional)
- Reps input field (optional)
- Checkmark to mark complete
- Delete button
- Visual styling for completed sets

**Navigation:**
- Embedded in `ExerciseSectionView` within `ActiveWorkoutView`

---

## History Views

### HistoryView.swift

**Description:** List of completed workouts grouped by date

**ViewModel:** `@StateObject viewModel: HistoryViewModel`

**Key Features:**
- Empty state when no workouts
- Workouts grouped by date (Today, Yesterday, Last 7 days, Months)
- Workout cards with summary info

**Contains:**
- `WorkoutHistoryRowView` (multiple)

**Navigation:**
- Embedded in ContentView TabView
- Navigates to `WorkoutHistoryDetailView`

---

### WorkoutHistoryDetailView.swift

**Description:** Detailed view of a completed workout

**ViewModel:** `@ObservedObject viewModel: HistoryViewModel`

**Key Features:**
- Workout header with metadata (duration, exercise count, set count)
- All exercises with their sets
- Delete workout option

**Contains:**
- `HistoricalExerciseSectionView` (multiple)
- `HistoricalSetRowView` (within HistoricalExerciseSectionView)
- `InfoBadge` (header section)

**Navigation:**
- Navigated to from `HistoryView`

---

## Exercise Library Views

### ExerciseListView.swift

**Description:** Exercise library with type filtering, equipment filtering, favorites, and search

**ViewModel:** `@StateObject viewModel: ExerciseLibraryViewModel`

**Key Features:**
- Segmented control for exercise type (Strength | Cardio)
- Strength exercises grouped by category (Chest, Back, Shoulders, Arms, Legs, Core)
- Cardio exercises grouped by category (Running, Cycling, Rowing, Stair Climber, Jump Rope, Swimming, Walking, HIIT)
- Search bar (searches within selected type)
- Equipment filter button (multi-select)
- Favorite toggle on each exercise row (star icon)
- Favorites section at top of list (if any exist)
- Equipment tags displayed on each exercise row
- Add custom exercise button
- Swipe to delete custom exercises

**Contains:**
- `ExerciseRowView` - Individual exercise row with favorite button and equipment tags
- `EquipmentFilterSheet` - Equipment multi-select filter

**Presents:**
- `AddExerciseSheet` (sheet)
- `EquipmentFilterSheet` (sheet)

**Navigation:**
- Embedded in ContentView TabView
- Navigates to `ExerciseDetailView`

---

### AddExerciseSheet.swift

**Description:** Sheet for creating custom exercise with comprehensive data

**ViewModel:** None (calls `ExerciseLibraryViewModel.addCustomExercise()`)

**Key Features:**
- Exercise name input
- Exercise type picker (Strength or Cardio)
- Category picker (dynamic based on type)
- Equipment multi-select (with equipment picker sheet)
- Primary muscles multi-select (for strength exercises)
- Secondary muscles multi-select (for strength exercises)
- Instructions text fields (setup, execution, tips - all optional)
- Save/cancel buttons

**Contains:**
- `EquipmentMultiSelectSheet` - Equipment selection sheet
- `MuscleMultiSelectSheet` - Muscle selection sheet

**Navigation:**
- Presented from `ExerciseListView` (sheet)

---

### ExerciseDetailView.swift

**Description:** Detailed view of an exercise showing equipment, muscles, instructions, PR, progress chart, and history

**ViewModel:** 
- `@StateObject progressViewModel: ProgressViewModel`
- `@StateObject libraryViewModel: ExerciseLibraryViewModel`

**Key Features:**
- Exercise header with category
- Equipment section with pill-shaped badges
- Muscles worked section (for strength exercises) with primary/secondary distinction
- Instructions section with Setup, Execution, and Tips subsections
- Favorite toggle button in navigation bar
- Personal record display (if any)
- Progress chart showing weight over time
- Recent workout history (last 10 times performed)
- Each history entry shows date, max weight, and all sets

**Contains:**
- `ExerciseProgressChartView` - Progress chart
- `HistoryRowView` - Individual history entries
- `FlowLayout` - Custom layout for wrapping equipment and muscle tags

**Navigation:**
- Navigated to from `ExerciseListView`

---

### ExerciseProgressChartView.swift

**Description:** Line chart showing weight progression over time for an exercise

**ViewModel:** None (receives data as parameters)

**Key Features:**
- Line chart with weight on Y-axis, dates on X-axis
- Highlights PR points with star symbols
- Empty state when no data
- Uses Swift Charts framework

**Navigation:**
- Embedded in `ExerciseDetailView`

---

### PRNotificationView.swift

**Description:** Celebratory notification shown when a PR is achieved during workout

**ViewModel:** None (receives PR as parameter)

**Key Features:**
- Animated star icon
- Shows exercise name, weight, and reps
- Haptic feedback on appearance
- Auto-dismisses after 3 seconds
- Overlay on active workout view

**Navigation:**
- Overlaid on `ActiveWorkoutFullScreenView` (conditional)

---

## Template Views

### TemplateListView.swift

**Description:** List of all workout templates

**ViewModel:** `@StateObject viewModel: TemplateViewModel`

**Key Features:**
- Empty state
- Template list with exercise count and last used date
- Swipe to delete
- Create template button

**Contains:**
- `TemplateRowView` (multiple)

**Presents:**
- `CreateTemplateView` (sheet)

**Navigation:**
- Navigates to `TemplateDetailView`
- Presented from `HomeView` (sheet)

---

### TemplateDetailView.swift

**Description:** View/edit template details and exercises

**ViewModel:** `@ObservedObject viewModel: TemplateViewModel`

**Key Features:**
- Template name editing
- List of exercises with drag-to-reorder
- Add exercise button
- Edit exercise defaults
- Delete exercise option

**Presents:**
- `AddExerciseToTemplateSheet` (sheet)
- `EditTemplateExerciseSheet` (sheet)

**Navigation:**
- Navigated to from `TemplateListView`

---

### CreateTemplateView.swift

**Description:** Create new workout template

**ViewModel:** `@ObservedObject viewModel: TemplateViewModel`

**Key Features:**
- Template name input
- Add exercises with default sets/reps/weight
- Reorder exercises
- Save template

**Presents:**
- `AddExerciseToTemplateSheet` (sheet)

**Navigation:**
- Presented from `TemplateListView` (sheet)

---

### AddExerciseToTemplateSheet.swift

**Description:** Sheet for adding exercise to template

**ViewModel:** None (calls `TemplateViewModel` methods)

**Key Features:**
- Exercise library search
- Category filter
- Default sets/reps/weight input

**Navigation:**
- Presented from `TemplateDetailView` or `CreateTemplateView` (sheet)

---

### AddExerciseToWorkoutSheet.swift

**Description:** Sheet for adding exercise to active workout

**ViewModel:** `@ObservedObject viewModel: ActiveWorkoutViewModel`

**Key Features:**
- Exercise library search
- Category filter
- Add selected exercise to workout

**Navigation:**
- Presented from `ActiveWorkoutView` (sheet)

---

### EditTemplateExerciseSheet.swift

**Description:** Sheet for editing exercise defaults in template

**ViewModel:** None (updates template exercise directly)

**Key Features:**
- Edit default sets
- Edit default reps
- Edit default weight

**Navigation:**
- Presented from `TemplateDetailView` (sheet)

---

## View Hierarchy

```
ContentView
├── TabView
│   ├── HomeView
│   │   └── TemplateListView (sheet)
│   │       └── CreateTemplateView (sheet)
│   │           └── AddExerciseToTemplateSheet (sheet)
│   │       └── TemplateDetailView
│   │           └── AddExerciseToTemplateSheet (sheet)
│   │           └── EditTemplateExerciseSheet (sheet)
│   │
│   ├── HistoryView
│   │   └── WorkoutHistoryDetailView
│   │
│   └── ExerciseListView
│       └── AddExerciseSheet (sheet)
│
├── FloatingWorkoutPill (conditional overlay)
│
└── ActiveWorkoutFullScreenView (fullScreenCover)
    ├── ActiveWorkoutView
    │   ├── ExerciseSectionView
    │   │   └── SetRowView (multiple)
    │   └── AddExerciseToWorkoutSheet (sheet)
    │
    └── RestTimerView (conditional)
```

## Navigation Patterns

### Sheets (Modal)
- Used for temporary forms/editors
- Dismissed with swipe or button
- Examples: AddExerciseSheet, CreateTemplateView, EditTemplateExerciseSheet

### NavigationLink (Push)
- Used for drill-down navigation
- Examples: TemplateDetailView, WorkoutHistoryDetailView

### FullScreenCover
- Used for immersive experiences
- Example: ActiveWorkoutFullScreenView

### Conditional Overlay
- Used for persistent UI elements
- Example: FloatingWorkoutPill
