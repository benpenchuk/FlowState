# Views

All SwiftUI views in the app, organized by purpose.

## Root & Navigation

### ContentView.swift

**Description:** Root view containing TabView and managing workout state

**ViewModel:** None (uses `@EnvironmentObject workoutState: WorkoutStateManager`)

**Key Features:**
- TabView with Home, History, Exercises, Profile tabs
- Manages appearance mode based on user preference (`.preferredColorScheme()`)
- Conditionally shows `FloatingWorkoutPill` when workout is active but minimized
- Presents full-screen workout via `fullScreenCover` when `isWorkoutFullScreen = true`
- Loads user profile for appearance and units preferences

**Presents:**
- `ActiveWorkoutFullScreenView` (fullScreenCover)

---

## Home & Dashboard

### HomeView.swift

**Description:** Home dashboard showing templates, recent PRs, weekly stats, and quick start options

**ViewModel:** 
- `@StateObject templateViewModel: TemplateViewModel`
- `@StateObject workoutViewModel: ActiveWorkoutViewModel`
- `@StateObject progressViewModel: ProgressViewModel`
- `@StateObject statsViewModel: HomeStatsViewModel`
- `@EnvironmentObject workoutState: WorkoutStateManager`

**Key Features:**
- Weekly stats card with workouts count, total time, and streak
- Activity calendar showing last 7 days of workouts
- Period selector (Last 7 Days / Last 30 Days) for stats
- Templates section with horizontal scrolling cards
- Recent PRs section (last 7 days)
- "See All" link to template list
- Quick start empty workout button
- Alerts for starting workouts (handles active workout conflicts)
- Skeleton loading states for stats and cards

**Contains:**
- `TemplateCardView` - Template cards
- `PRCardView` - PR display cards
- `SkeletonStatsCard` - Stats loading skeleton
- `SkeletonTemplateCard` - Template card loading skeleton
- `SkeletonPRCard` - PR card loading skeleton

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
- Uses `ActiveWorkoutLayout` constants for consistent spacing
- Scroll offset tracking for header collapse/expand

**Contains:**
- `ExerciseSectionView` (multiple, expandable/collapsible)
- `SetRowView` (within ExerciseSectionView)
- `RestTimerView` (conditionally shown)
- `PRNotificationView` (conditionally shown when PR detected)

**Presents:**
- `AddExerciseToWorkoutSheet` (sheet)
- `ReorderSetsSheet` (sheet)
- `WorkoutCompletionView` (sheet)
- `CustomNumPadView` (overlay for input)

**Navigation:**
- Presented via `fullScreenCover` from `ContentView`

---

### ActiveWorkoutLayout.swift

**Description:** Centralized layout constants for active workout UI

**ViewModel:** None (static constants)

**Key Features:**
- Content padding constants
- Exercise card padding and corner radius
- Workout section spacing
- Header collapse/expand thresholds (hysteresis)
- Bottom scroll buffer

**Usage:**
- Prevents conflicting nested padding
- Reduces horizontal clipping on smaller devices
- Ensures consistent spacing across workout views
- Used by `ActiveWorkoutFullScreenView`, `ActiveWorkoutView`, and related components

**Constants:**
- `contentPadding: CGFloat = 16`
- `exerciseCardPadding: CGFloat = 16`
- `workoutSectionSpacing: CGFloat = 20`
- `exerciseCardCornerRadius: CGFloat = 16`
- `headerCollapseThreshold: CGFloat = 60`
- `headerExpandThreshold: CGFloat = 40`
- `bottomScrollBuffer: CGFloat = 32`


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
- Sound toggle button (speaker icon)

**Navigation:**
- Embedded in `ActiveWorkoutFullScreenView` (conditionally shown)

---

### CustomNumPadView.swift

**Description:** Custom number pad component with built-in Done button

**ViewModel:** None (uses bindings for input/output)

**Key Features:**
- Custom numpad with number buttons (0-9)
- Decimal point button for weight input
- Backspace button for corrections
- Done button to confirm input
- Clean design matching app style
- Supports decimal weights and whole number reps

**Navigation:**
- Presented as overlay when weight/reps fields are tapped
- Integrated into `SetRowView` and `ActiveWorkoutView` (for notes)

---

### SetRowView.swift

**Description:** Individual set input row with drag reordering and labels

**ViewModel:** None (receives callbacks from parent)

**Key Features:**
- Set number display
- Weight input field (optional) with unit conversion
- Unit label (lbs or kg) based on user preference
- Reps input field (optional)
- Checkmark to mark complete
- Delete button (swipe-to-delete)
- Set labels with colored badges (Warmup, Failure, Drop Set, PR Attempt)
- Visual styling for completed sets
- Converts weight for display (lbs ↔ kg) based on user preference
- Stores all weights internally as lbs
- Uses `ActiveWorkoutLayout` constants for spacing

**Navigation:**
- Embedded in `ExerciseSectionView` within `ActiveWorkoutView`

---

### ReorderSetsSheet.swift

**Description:** Dedicated sheet for reordering sets within an exercise

**ViewModel:** `@ObservedObject viewModel: ActiveWorkoutViewModel`

**Key Features:**
- List view with drag handles for reordering
- Shows all sets for the exercise
- Displays set number, weight, and reps
- Always in edit mode (reorder controls always visible)
- Footer explaining the reorder functionality
- Updates set order when dismissed

**Navigation:**
- Presented as sheet from `ActiveWorkoutFullScreenView` or `ExerciseSectionView`

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
- Effort rating display (if available) with visual 1-10 scale indicator
- Total rest time display (if tracked)
- Notes display (if provided)
- All exercises with their sets
- Delete workout option

**Contains:**
- `HistoricalExerciseSectionView` (multiple)
- `HistoricalSetRowView` (within HistoricalExerciseSectionView)
- `InfoBadge` (header section)

**Navigation:**
- Navigated to from `HistoryView`

---

### WorkoutCompletionView.swift

**Description:** Optional feedback screen shown when user finishes a workout

**ViewModel:** None (receives callbacks from parent)

**Key Features:**
- Header section with workout name, duration, exercise count, and set count
- Effort scale (1-10) with color-coded buttons:
  - 1-2: Green (Light)
  - 3-4: Yellow
  - 5-6: Orange
  - 7-8: Red
  - 9-10: Dark red/purple (All Out)
- Collapsible notes section with multi-line text field
- "Save Workout" button (primary, saves with feedback)
- "Skip & Save" button (secondary, saves without feedback)
- All fields are optional - user can skip everything

**Navigation:**
- Presented as sheet from `ActiveWorkoutFullScreenView` when "Finish Workout" is tapped

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
- Muscle group filter bar (`ExerciseFilterBar`) with quick filter chips
- Equipment filter button (multi-select)
- Favorite toggle on each exercise row (star icon)
- Favorites section at top of list (if any exist)
- Equipment tags displayed on each exercise row
- Add custom exercise button
- Swipe to delete custom exercises
- Skeleton loading states

**Contains:**
- `ExerciseRowCard` - Individual exercise row card component
- `ExerciseFilterBar` - Horizontal filter bar with muscle group chips
- `SkeletonExerciseRow` - Exercise row loading skeleton
- `EquipmentFilterSheet` - Equipment multi-select filter

**Presents:**
- `AddExerciseSheet` (sheet)
- `EditExerciseSheet` (sheet)
- `EquipmentFilterSheet` (sheet)

**Navigation:**
- Embedded in ContentView TabView
- Navigates to `ExerciseDetailView`

---

### AddExerciseSheet.swift

**Description:** Sheet for creating custom exercise with comprehensive data

**ViewModel:** `@ObservedObject viewModel: ExerciseLibraryViewModel`

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

### EditExerciseSheet.swift

**Description:** Sheet for editing existing custom exercises

**ViewModel:** `@ObservedObject viewModel: ExerciseLibraryViewModel`

**Key Features:**
- Pre-populated with exercise data
- Exercise name editing
- Exercise type picker (Strength or Cardio)
- Category picker (dynamic based on type)
- Equipment multi-select (with equipment picker sheet)
- Primary muscles multi-select (for strength exercises)
- Secondary muscles multi-select (for strength exercises)
- Instructions text fields (setup, execution, tips - all editable)
- Save/cancel buttons
- Updates exercise via ViewModel

**Contains:**
- `EquipmentMultiSelectSheet` - Equipment selection sheet
- `MuscleMultiSelectSheet` - Muscle selection sheet

**Navigation:**
- Presented from `ExerciseListView` (sheet)

---

### ExerciseRowCard.swift

**Description:** Reusable card component for displaying exercise rows in lists

**ViewModel:** None (receives exercise data as parameter)

**Key Features:**
- Exercise name display
- Category badge
- Equipment tags display
- Favorite toggle button (star icon)
- Tap to navigate to exercise details
- Consistent styling across exercise lists
- Supports custom actions via callbacks

**Navigation:**
- Embedded in `ExerciseListView`
- Navigates to `ExerciseDetailView` on tap

---

### ExerciseFilterBar.swift

**Description:** Horizontal filter bar with muscle group filter chips

**ViewModel:** None (uses bindings for filter state)

**Key Features:**
- Horizontal scrolling filter chips
- Muscle group filters (Chest, Back, Legs, Shoulders, Arms, Core)
- Each chip shows icon and title
- Selected state visual feedback
- "More Filters" button showing active filter count
- Tap to toggle filter selection
- Calls callback when "More Filters" is tapped

**Contains:**
- `FilterChip` - Individual filter chip component

**Navigation:**
- Embedded in `ExerciseListView`

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

### LabelPickerSheet.swift

**Description:** Sheet for selecting set labels (Warmup, Failure, Drop Set, PR Attempt)

**ViewModel:** None (uses bindings for selection)

**Key Features:**
- Predefined label options with colored badges
- Single selection (tap to choose)
- Cancel option to clear label
- Visual preview of label appearance

**Navigation:**
- Presented from `SetRowView` when label area is tapped (sheet)

---

## Profile & Settings Views

### ProfileView.swift

**Description:** User profile view showing stats and achievements

**ViewModel:** `@StateObject profileViewModel: ProfileViewModel`

**Key Features:**
- Profile header with editable name
- Member since date
- Stats cards: Total Workouts, Personal Records, Current Streak
- Recent Achievements section (last 3 PRs)
- Settings button (gear icon) in navigation bar

**Contains:**
- `StatCard` - Stats display cards
- `PRCard` - Personal record display cards

**Presents:**
- `SettingsView` (sheet)

**Navigation:**
- Embedded in ContentView TabView

---

### SettingsView.swift

**Description:** Settings screen with preferences, data management, and about

**ViewModel:** `@StateObject profileViewModel: ProfileViewModel`

**Key Features:**
- Preferences section:
  - Units picker (lbs / kg)
  - Default Rest Time picker (30s, 60s, 90s, 120s, 180s)
  - Appearance picker (Dark / Light / System)
- Data section:
  - Export Workout Data (placeholder alert)
  - Clear All Data (with confirmation)
- About section:
  - App Version (from bundle)
  - Send Feedback (opens mail composer)
  - About FlowState (alert with description)

**Contains:**
- `MailComposeView` - Email composer for feedback

**Navigation:**
- Presented from `ProfileView` (sheet)

---

## Skeleton Loading Views

### Skeletons/

Skeleton loading views provide visual feedback while data is loading.

#### SkeletonExerciseRow.swift

**Description:** Skeleton loading state for exercise rows

**Usage:** Shown in `ExerciseListView` while exercises are loading

---

#### SkeletonPRCard.swift

**Description:** Skeleton loading state for PR cards

**Usage:** Shown in `HomeView` while recent PRs are loading

---

#### SkeletonStatsCard.swift

**Description:** Skeleton loading state for stats cards

**Usage:** Shown in `HomeView` while statistics are calculating

---

#### SkeletonTemplateCard.swift

**Description:** Skeleton loading state for template cards

**Usage:** Shown in `HomeView` and `TemplateListView` while templates are loading

---

#### SkeletonWorkoutHistoryCard.swift

**Description:** Skeleton loading state for workout history cards

**Usage:** Shown in `HistoryView` while workout history is loading

---

## View Hierarchy

```
ContentView
├── TabView
│   ├── HomeView
│   │   ├── SkeletonStatsCard (conditional)
│   │   ├── SkeletonTemplateCard (conditional)
│   │   ├── SkeletonPRCard (conditional)
│   │   └── TemplateListView (sheet)
│   │       └── CreateTemplateView (sheet)
│   │           └── AddExerciseToTemplateSheet (sheet)
│   │       └── TemplateDetailView
│   │           └── AddExerciseToTemplateSheet (sheet)
│   │           └── EditTemplateExerciseSheet (sheet)
│   │
│   ├── HistoryView
│   │   ├── SkeletonWorkoutHistoryCard (conditional)
│   │   └── WorkoutHistoryDetailView
│   │
│   ├── ExerciseListView
│   │   ├── ExerciseFilterBar
│   │   ├── ExerciseRowCard (multiple)
│   │   ├── SkeletonExerciseRow (conditional)
│   │   ├── AddExerciseSheet (sheet)
│   │   └── EditExerciseSheet (sheet)
│   │
│   └── ProfileView
│       └── SettingsView (sheet)
│
├── FloatingWorkoutPill (conditional overlay)
│
└── ActiveWorkoutFullScreenView (fullScreenCover)
    ├── ExerciseSectionView (multiple)
    │   └── SetRowView (multiple)
    ├── AddExerciseToWorkoutSheet (sheet)
    ├── ReorderSetsSheet (sheet)
    ├── RestTimerView (conditional)
    ├── PRNotificationView (conditional)
    └── WorkoutCompletionView (sheet)
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
