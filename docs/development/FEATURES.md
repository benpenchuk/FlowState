# Features

## Current Features

### ✅ Exercise Library

**Status:** Complete

**Description:**
- Browse exercises by type (Strength or Cardio) with segmented control
- Strength exercises grouped by category (Chest, Back, Shoulders, Arms, Legs, Core)
- Cardio exercises grouped by category (Running, Cycling, Rowing, Stair Climber, Jump Rope, Swimming, Walking, HIIT)
- Search exercises by name (within selected type)
- Filter by equipment (multi-select)
- Favorite exercises (star icon, tap to toggle)
- Favorites section at top of list
- View exercise details with equipment tags, muscles worked, and structured instructions
- Create custom exercises with full data (type, category, equipment, muscles, instructions)
- Comprehensive pre-seeded library with ~80+ exercises including detailed instructions

**Implementation:**
- `Models/Exercise.swift` - Exercise model with ExerciseType, Equipment, ExerciseInstructions
- `ViewModels/ExerciseLibraryViewModel.swift` - Library management and seeding
- `Views/ExerciseListView.swift` - Main library UI with filtering and favorites
- `Views/AddExerciseSheet.swift` - Create custom exercise with all fields
- `Views/ExerciseDetailView.swift` - Exercise details with equipment, muscles, instructions

**User Flow:**
1. Navigate to "Exercises" tab
2. Select exercise type (Strength or Cardio) via segmented control
3. Optionally filter by equipment using filter button
4. Search exercises by name
5. Tap star icon to favorite/unfavorite exercises
6. Tap exercise to view details (equipment, muscles, instructions, progress chart, history)
7. Tap "+" to create custom exercise
8. Fill in type, category, equipment, muscles (for strength), instructions
9. Save exercise

---

### ✅ Workout Templates

**Status:** Complete

**Description:**
- Create reusable workout templates
- Add exercises to templates with default sets/reps/weight
- Reorder exercises within template
- Edit existing templates
- Delete templates
- Quick start workouts from templates

**Implementation:**
- `Models/WorkoutTemplate.swift` - Template model
- `Models/TemplateExercise.swift` - Exercise config in template
- `ViewModels/TemplateViewModel.swift` - Template CRUD
- `Views/TemplateListView.swift` - Template list
- `Views/CreateTemplateView.swift` - Create/edit template
- `Views/TemplateDetailView.swift` - View/edit template
- `Views/AddExerciseToTemplateSheet.swift` - Add exercises to template
- `Views/EditTemplateExerciseSheet.swift` - Edit exercise in template

**User Flow (Create Template):**
1. Navigate to templates (via HomeView → "See All")
2. Tap "+" to create new template
3. Enter template name
4. Add exercises with default sets/reps/weight
5. Reorder exercises via drag-and-drop
6. Save template

**User Flow (Start from Template):**
1. View templates on HomeView
2. Tap template card
3. Confirm start (or discard active workout if exists)
4. Workout opens in full-screen with pre-populated exercises and sets

---

### ✅ Active Workout Logging

**Status:** Complete

**Description:**
- Start empty workout or from template
- Full-screen workout mode
- Add exercises to active workout with smart default sets
- Log sets with weight and reps
- Mark sets as complete
- Add/remove sets dynamically
- Edit workout name
- Timer shows elapsed time

**Smart Default Sets:**
When adding an exercise to an active workout, the app automatically creates pre-filled sets:
- If exercise exists in workout history: Creates sets with weight/reps from most recent session
- If no history: Creates 3 empty sets ready for input
- Maintains set count from history (if you did 5 sets last time, creates 5 this time)
- All sets start as not completed, user can edit all values before completing
- Eliminates repetitive "Add Set" button tapping and data entry

**Implementation:**
- `Views/ActiveWorkoutFullScreenView.swift` - Full-screen mode
- `Views/ActiveWorkoutView.swift` - Workout UI
- `Views/SetRowView.swift` - Individual set input
- `Views/AddExerciseToWorkoutSheet.swift` - Add exercise to workout
- `ViewModels/ActiveWorkoutViewModel.swift` - Workout operations, smart defaults
- `ViewModels/WorkoutStateManager.swift` - App-wide state

**User Flow:**
1. Start workout from template or empty
2. Full-screen workout view appears
3. Edit set: tap weight/reps fields, enter values
4. Mark set complete: tap checkmark (automatically captures timestamp)
5. Add set: tap "Add Set" button (rarely needed - sets auto-created)
6. Add exercise: tap "Add Exercise", select from library
   - Exercise added with smart default sets (from history or 3 empty)
7. Finish workout: tap "Finish Workout" button
8. Workout completion screen appears with optional feedback:
   - Rate effort (1-10 scale, optional)
   - Add notes (optional)
   - Save workout or skip feedback
9. Workout saved to history with all captured data

---

### ✅ Set Reordering Within Exercises

**Status:** Complete

**Description:**
- Drag-and-drop sets to reorder within an exercise
- Useful for adding warmup sets after the fact
- Visual drag handles on the right side of set rows
- Smooth animations during reordering

**Implementation:**
- `Views/SetRowView.swift` - Added drag handle and reordering logic
- `ViewModels/ActiveWorkoutViewModel.swift` - Set reordering methods
- `Models/SetRecord.swift` - Order field for maintaining sequence

**User Flow:**
1. Long press and drag the handle on the right side of a set row
2. Drag to desired position within the exercise
3. Release to complete reordering
4. Set order updates immediately

---

### ✅ Set Labels

**Status:** Complete

**Description:**
- Tag sets with labels: Warmup, Failure, Drop Set, PR Attempt
- Visual indicator (colored pill/badge next to set)
- Optional labels that don't affect workout data
- Quick selection via picker sheet

**Implementation:**
- `Views/LabelPickerSheet.swift` - Label selection UI
- `Views/SetRowView.swift` - Label display and picker integration
- `Models/SetRecord.swift` - Label enum and field

**User Flow:**
1. Tap the label area on a set row (shows current label or "Add Label")
2. Select from predefined labels (Warmup, Failure, Drop Set, PR Attempt)
3. Label appears as colored pill next to the set
4. Tap label to change or remove

---

### ✅ Per-Exercise Notes During Workout

**Status:** Complete

**Description:**
- Add notes to individual exercises during workout
- Separate from overall workout notes
- Collapsible text field to save space
- Useful for tracking form issues, equipment notes, etc.

**Implementation:**
- `Views/ActiveWorkoutView.swift` - Exercise notes integration
- `Models/WorkoutEntry.swift` - Notes field per exercise

**User Flow:**
1. During active workout, look for notes field under each exercise
2. Tap to expand and enter notes
3. Notes auto-save as you type
4. Collapse to save space when not editing

---

### ✅ Expand/Collapse Exercises

**Status:** Complete

**Description:**
- Collapse completed exercises to reduce scrolling
- Tap exercise header to toggle expansion state
- Visual indicators show completion status
- Useful for long workouts with many exercises

**Implementation:**
- `Views/ActiveWorkoutView.swift` - Exercise expansion state management
- `Models/WorkoutEntry.swift` - Expanded state tracking

**User Flow:**
1. During workout, completed exercises can be collapsed
2. Tap exercise header (name area) to toggle expansion
3. Collapsed exercises show summary (exercise name, sets completed)
4. Expand to see all sets and add more

---

### ✅ Custom Number Pad

**Status:** Complete

**Description:**
- Custom numpad component with built-in "Done" button
- Replaces native iOS keyboard for weight and rep input
- Clean design matching app style
- Decimal point support for weights, whole numbers for reps
- Dismisses keyboard immediately when "Done" is tapped

**Implementation:**
- `Views/CustomNumPadView.swift` - Custom numpad component
- Integrated into `SetRowView` for weight/reps input
- `Views/ActiveWorkoutView.swift` - Uses custom numpad for exercise notes

**User Flow:**
1. Tap weight or reps field in a set row
2. Custom numpad appears instead of native keyboard
3. Enter value using number buttons
4. Tap "Done" to confirm and dismiss numpad
5. Keyboard never appears, improving workout flow

---

### ✅ App State Persistence & Resume

**Status:** Complete

**Description:**
- Resume incomplete workout on app launch
- Detects active workout on startup
- Shows "Resume Workout" or "Discard" alert
- Restores workout state on resume
- Prevents data loss from accidental app closure

**Implementation:**
- `ViewModels/WorkoutStateManager.swift` - App launch resume logic
- `FlowStateApp.swift` - App launch detection
- `Views/ResumeWorkoutSheet.swift` - Resume prompt UI

**User Flow:**
1. Force-quit app mid-workout
2. Reopen app
3. Alert appears: "Resume your active workout?"
4. Choose "Resume" to continue workout
5. Choose "Discard" to start fresh
6. Workout state fully restored on resume

---

### ✅ Enhanced Rest Timer

**Status:** Complete

**Description:**
- Rest timer continues when phone is locked/app backgrounded
- Plays sound notification when rest timer completes
- Haptic feedback included
- Toggle button to enable/disable sound
- Uses wall-clock time tracking for accuracy

**Implementation:**
- `ViewModels/RestTimerViewModel.swift` - Wall-clock time tracking
- `Views/RestTimerView.swift` - Sound toggle button
- System sound notification with haptic feedback

**User Flow:**
1. Complete a set to start rest timer
2. Lock phone or background app
3. Rest timer continues running
4. When timer completes, sound plays and haptic feedback occurs
5. Tap sound toggle button to enable/disable notifications

---

### ✅ Floating Workout Pill

**Status:** Complete

**Description:**
- Minimize workout (swipe down or tap minimize)
- Floating pill appears showing elapsed time
- Timer continues running
- Tap pill to return to full-screen workout
- Only shown when workout is active but not full-screen

**Implementation:**
- `Views/FloatingWorkoutPill.swift` - Pill UI
- `ContentView.swift` - Conditionally shows pill
- `ViewModels/WorkoutStateManager.swift` - Manages `isWorkoutFullScreen` state

**User Flow:**
1. During active workout, swipe down or tap minimize
2. Full-screen dismisses
3. Floating pill appears at bottom of screen
4. Pill shows elapsed time (MM:SS format)
5. Tap pill to return to full-screen workout
6. Timer keeps running in background

---

### ✅ Rest Timer

**Status:** Complete

**Description:**
- Auto-starts when set is marked complete
- Circular progress indicator
- Adjustable duration (+30s, -30s buttons)
- Skip button to stop timer
- Default 90 seconds
- Stops when new set is started or workout finishes

**Implementation:**
- `Views/RestTimerView.swift` - Timer UI
- `ViewModels/RestTimerViewModel.swift` - Timer logic
- `ViewModels/WorkoutStateManager.swift` - Timer integration

**User Flow:**
1. Mark set as complete (tap checkmark)
2. Rest timer automatically starts
3. Circular progress shows countdown
4. Adjust time: tap +30s or -30s
5. Skip rest: tap "Skip" button
6. Timer stops when user logs next set or workout ends

---

### ✅ Workout History

**Status:** Complete

**Description:**
- View all completed workouts
- Grouped by date (Today, Yesterday, Last 7 days, Months)
- Workout details: name, duration, exercise count, set count
- Individual workout detail view with enhanced data:
  - Effort rating (1-10 scale with visual indicator)
  - Notes (if provided)
  - Total rest time (if tracked)
- Delete workouts
- View sets and weights for each exercise

**Implementation:**
- `Views/HistoryView.swift` - History list
- `Views/WorkoutHistoryDetailView.swift` - Workout details
- `ViewModels/HistoryViewModel.swift` - History queries

**User Flow:**
1. Navigate to "History" tab
2. See workouts grouped by date
3. Tap workout to view details
4. See all exercises and sets logged
5. View effort rating, notes, and total rest time (if available)
6. Tap trash icon to delete workout

---

### ✅ Single Active Workout Enforcement

**Status:** Complete

**Description:**
- Only one active workout allowed at a time
- Starting new workout shows alert if active workout exists
- Option to discard existing workout
- Prevents data conflicts

**Implementation:**
- `ViewModels/ActiveWorkoutViewModel.swift` - `hasActiveWorkout()` check
- `Views/HomeView.swift` - Alert logic

**User Flow:**
1. User has active workout
2. Tries to start new workout
3. Alert appears: "You have an active workout. Discard it and start a new one?"
4. User can cancel or discard existing and start new

---

### ✅ Profile & Settings

**Status:** Complete

**Description:**
- Profile tab showing user stats and achievements
- User profile with editable name
- Stats display: Total Workouts, Personal Records, Current Streak
- Recent Achievements section (last 3 PRs)
- Settings screen with preferences:
  - Units preference (lbs / kg)
  - Default Rest Time (30s, 60s, 90s, 120s, 180s)
  - Appearance Mode (Dark / Light / System)
- Data management:
  - Export Workout Data (placeholder)
  - Clear All Data (with confirmation)
- About section with app version, feedback, and about info
- Units conversion throughout app (all weights stored as lbs, converted for display)
- Appearance mode applied app-wide

**Implementation:**
- `Models/UserProfile.swift` - Profile model with Units and AppearanceMode enums
- `ViewModels/ProfileViewModel.swift` - Profile management and stats calculation
- `Views/ProfileView.swift` - Profile display with stats cards
- `Views/SettingsView.swift` - Settings screen
- `Views/ContentView.swift` - Appearance mode implementation
- `Views/SetRowView.swift` - Units conversion in set input
- `Views/WorkoutHistoryDetailView.swift` - Units in history
- `Views/ExerciseDetailView.swift` - Units in exercise details
- `Views/ActiveWorkoutFullScreenView.swift` - Default rest time from profile

**User Flow:**
1. Navigate to Profile tab
2. View stats and recent achievements
3. Tap gear icon to open Settings
4. Adjust preferences (units, rest time, appearance)
5. Changes apply immediately throughout app

---

### ✅ Progress Tracking & Personal Records

**Status:** Complete

**Description:**
- Automatic PR detection when sets are completed
- Celebratory PR notification with haptic feedback during workout
- Progress charts showing weight progression over time
- Exercise detail view with PR, chart, and history
- Recent PRs displayed on home dashboard (last 7 days)
- PRs stored in SwiftData for performance

**Implementation:**
- `Models/PersonalRecord.swift` - PR model
- `ViewModels/ProgressViewModel.swift` - PR detection and progress tracking
- `Views/ExerciseDetailView.swift` - Exercise details with PR and chart
- `Views/ExerciseProgressChartView.swift` - Progress chart using Swift Charts
- `Views/PRNotificationView.swift` - PR celebration UI
- `Views/HomeView.swift` - Recent PRs section
- `ViewModels/ActiveWorkoutViewModel.swift` - PR detection integration

**User Flow:**
1. User completes a set during workout
2. System checks if weight exceeds previous PR
3. If PR, shows celebratory notification with haptic feedback
4. PR is saved to SwiftData
5. PR appears in Recent PRs on Home dashboard
6. User can view exercise details to see PR, progress chart, and history

---

## Feature Status Table

| Feature | Status | Files | Notes |
|---------|--------|-------|-------|
| Exercise Library | ✅ Complete | Exercise.swift, ExerciseLibraryViewModel.swift, ExerciseListView.swift | Search, categories, custom exercises |
| Workout Templates | ✅ Complete | WorkoutTemplate.swift, TemplateViewModel.swift, TemplateListView.swift | Create, edit, delete, reorder |
| Active Workout Logging | ✅ Complete | ActiveWorkoutView.swift, ActiveWorkoutViewModel.swift, SetRowView.swift | Full-screen mode, set logging |
| Custom Number Pad | ✅ Complete | CustomNumPadView.swift, SetRowView.swift | Built-in Done button, replaces keyboard |
| Set Deletion | ✅ Complete | SetRowView.swift, ActiveWorkoutViewModel.swift | Swipe-to-delete with confirmation |
| Exercise Deletion | ✅ Complete | ActiveWorkoutView.swift, ActiveWorkoutViewModel.swift | Trash icon with confirmation |
| Workout Name Locking | ✅ Complete | ActiveWorkoutView.swift | Prevents editing during active workout |
| App State Persistence | ✅ Complete | WorkoutStateManager.swift, FlowStateApp.swift, ResumeWorkoutSheet.swift | Resume workout on app launch |
| Enhanced Rest Timer | ✅ Complete | RestTimerView.swift, RestTimerViewModel.swift | Wall-clock time, sound notifications, toggle |
| Set Reordering | ✅ Complete | SetRowView.swift, ActiveWorkoutViewModel.swift, SetRecord.swift | Drag-and-drop within exercises |
| Set Labels | ✅ Complete | LabelPickerSheet.swift, SetRowView.swift, SetRecord.swift | Warmup, Failure, Drop Set, PR Attempt |
| Per-Exercise Notes | ✅ Complete | ActiveWorkoutView.swift, WorkoutEntry.swift | Individual exercise notes during workout |
| Exercise Expand/Collapse | ✅ Complete | ActiveWorkoutView.swift, WorkoutEntry.swift | Collapse completed exercises |
| Floating Workout Pill | ✅ Complete | FloatingWorkoutPill.swift, ContentView.swift | Minimize/resume |
| Workout History | ✅ Complete | HistoryView.swift, HistoryViewModel.swift | List, detail, delete |
| Single Active Workout | ✅ Complete | ActiveWorkoutViewModel.swift, HomeView.swift | Enforcement via alerts |
| Dark Theme | ✅ Complete | ContentView.swift | App-wide dark mode (now configurable) |
| Progress Tracking & PRs | ✅ Complete | PersonalRecord.swift, ProgressViewModel.swift, ExerciseDetailView.swift, ExerciseProgressChartView.swift, PRNotificationView.swift | PR detection, charts, history |
| Profile & Settings | ✅ Complete | UserProfile.swift, ProfileViewModel.swift, ProfileView.swift, SettingsView.swift | Profile stats, preferences, units, appearance |
| Sticky Header with Timers | ✅ Complete | ActiveWorkoutFullScreenView.swift | Fixed header with timers, scrollable content below |
| Equipment Icons on Exercises | ✅ Complete | ActiveWorkoutView.swift | SF Symbols showing equipment type next to exercise names |
| Better Set Entry UI/Spacing | ✅ Complete | SetRowView.swift | Larger tap targets (60pt), card backgrounds, improved spacing and hierarchy |

---

## User Flows

### Complete Workout Flow

1. **Start Workout**
   - User taps template card on HomeView
   - Confirms start (or discards active workout if exists)
   - Workout opens in full-screen mode

2. **Log Sets**
   - User edits weight/reps for first set
   - Taps checkmark to mark complete
   - Rest timer auto-starts

3. **Rest Between Sets**
   - User waits for rest timer (or skips)
   - Timer shows circular progress

4. **Continue Sets**
   - User logs next set
   - Rest timer stops when set is logged
   - Repeat for all sets

5. **Add Exercise (if needed)**
   - User taps "Add Exercise"
   - Selects exercise from library
   - Logs sets for new exercise

6. **Finish Workout**
   - User taps "Finish Workout"
   - Workout completion screen appears:
     - Shows workout summary (name, duration, exercises, sets)
     - Optional effort rating (1-10 scale with color coding)
     - Optional notes field (collapsible)
     - "Save Workout" or "Skip & Save" buttons
   - User can provide feedback or skip
   - Workout marked as completed with all captured data:
     - `completedAt = Date()`
     - `effortRating` (if provided)
     - `notes` (if provided)
     - `totalRestTime` (automatically calculated)
   - Returns to HomeView
   - Workout appears in History tab with all data visible

### Template Creation Flow

1. **Navigate to Templates**
   - User taps "See All" on HomeView templates section
   - TemplateListView opens

2. **Create Template**
   - User taps "+" button
   - Enters template name
   - Taps "Add Exercise"

3. **Add Exercises**
   - Selects exercise from library
   - Sets default sets, reps, weight
   - Adds more exercises as needed

4. **Reorder Exercises**
   - Drags exercises to reorder
   - Order saved automatically

5. **Save Template**
   - Template saved to SwiftData
   - Appears in template list
   - Available for quick start

### History Review Flow

1. **View History**
   - User navigates to History tab
   - Sees workouts grouped by date

2. **View Details**
   - Taps workout in list
   - Sees all exercises and sets
   - Views weights and reps for each set

3. **Delete Workout (optional)**
   - Taps trash icon
   - Confirms deletion
   - Workout removed from history

---

## Partial Features

None currently - all listed features are complete.

---

## Not Started

See [TODO.md](../tasks/future/TODO.md) for planned features.
