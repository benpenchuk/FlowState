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
- Add exercises to active workout
- Log sets with weight and reps
- Mark sets as complete
- Add/remove sets dynamically
- Edit workout name
- Timer shows elapsed time

**Implementation:**
- `Views/ActiveWorkoutFullScreenView.swift` - Full-screen mode
- `Views/ActiveWorkoutView.swift` - Workout UI
- `Views/SetRowView.swift` - Individual set input
- `Views/AddExerciseToWorkoutSheet.swift` - Add exercise to workout
- `ViewModels/ActiveWorkoutViewModel.swift` - Workout operations
- `ViewModels/WorkoutStateManager.swift` - App-wide state

**User Flow:**
1. Start workout from template or empty
2. Full-screen workout view appears
3. Edit set: tap weight/reps fields, enter values
4. Mark set complete: tap checkmark (automatically captures timestamp)
5. Add set: tap "Add Set" button
6. Add exercise: tap "Add Exercise", select from library
7. Finish workout: tap "Finish Workout" button
8. Workout completion screen appears with optional feedback:
   - Rate effort (1-10 scale, optional)
   - Add notes (optional)
   - Save workout or skip feedback
9. Workout saved to history with all captured data

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
| Floating Workout Pill | ✅ Complete | FloatingWorkoutPill.swift, ContentView.swift | Minimize/resume |
| Rest Timer | ✅ Complete | RestTimerView.swift, RestTimerViewModel.swift | Auto-start, adjustable |
| Workout History | ✅ Complete | HistoryView.swift, HistoryViewModel.swift | List, detail, delete |
| Single Active Workout | ✅ Complete | ActiveWorkoutViewModel.swift, HomeView.swift | Enforcement via alerts |
| Dark Theme | ✅ Complete | ContentView.swift | App-wide dark mode (now configurable) |
| Progress Tracking & PRs | ✅ Complete | PersonalRecord.swift, ProgressViewModel.swift, ExerciseDetailView.swift, ExerciseProgressChartView.swift, PRNotificationView.swift | PR detection, charts, history |
| Profile & Settings | ✅ Complete | UserProfile.swift, ProfileViewModel.swift, ProfileView.swift, SettingsView.swift | Profile stats, preferences, units, appearance |

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

See `TODO.md` for planned features.
