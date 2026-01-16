# TODO / Future Features

Features and improvements planned but not yet implemented.

## High Priority

### 📊 Progress Tracking & Charts

**Status:** ✅ Complete (Basic Implementation)

**Description:**
- ✅ Show weight progression charts for each exercise over time
- ✅ Visualize strength gains over time
- ✅ Progress chart using Swift Charts
- ⏳ Filter charts by time period (week, month, 3 months, year, all time) - Future enhancement
- ⏳ Support different metrics (1RM, volume, max weight, average weight) - Future enhancement

**Implementation:**
- `ViewModels/ProgressViewModel.swift` - Progress calculation logic
- `Views/ExerciseProgressChartView.swift` - Progress chart UI
- `Views/ExerciseDetailView.swift` - Exercise details with chart and history

**Related Models:**
- `PersonalRecord.swift` - PR model for tracking records

**Future Enhancements:**
- Time period filters for charts
- Additional metrics (volume, 1RM estimates)
- Chart preferences storage

---

### 🏆 Personal Records (PRs)

**Status:** ✅ Complete

**Description:**
- ✅ Detect when user lifts more weight than previous max for an exercise
- ✅ Display PR notification during workout with celebration
- ✅ Show recent PRs on Home dashboard
- ✅ Track PRs by exercise (highest weight for at least 1 rep)
- ✅ Celebrate PRs with haptics/animations
- ✅ Store PR records in SwiftData

**Implementation:**
- `Models/PersonalRecord.swift` - PR model
- `ViewModels/ProgressViewModel.swift` - PR detection and queries
- `Views/PRNotificationView.swift` - PR celebration UI
- `Views/HomeView.swift` - Recent PRs section
- `Views/ExerciseDetailView.swift` - PR display

**Future Enhancements:**
- PR tracking by rep range
- 1RM equivalent calculations
- PR badges in SetRowView

---

### 📈 Home Dashboard Stats

**Status:** Not Started

**Description:**
- Show workout streaks (consecutive days)
- Weekly summary (workouts completed, total sets, total volume)
- Recent PRs section
- Quick stats cards (total workouts, total exercises, favorite exercises)

**Implementation Notes:**
- Calculate streaks from completed workout dates
- Aggregate weekly/monthly statistics
- Query recent PRs (see above)
- Display cards on HomeView

**Files to Create:**
- `ViewModels/DashboardViewModel.swift` - Stats calculation
- `Views/DashboardStatsView.swift` - Stats cards UI
- `Views/StreakView.swift` - Streak indicator

**Related Features:**
- Progress tracking (uses same data)
- PRs (displays recent PRs)

---

## Medium Priority

### ✏️ Edit Past Workouts

**Status:** Not Started

**Description:**
- Allow editing completed workouts
- Change sets, weights, reps
- Add/remove exercises from past workouts
- Update workout notes
- Maintain workout completion date

**Implementation Notes:**
- Add edit mode to `WorkoutHistoryDetailView`
- Allow set editing similar to active workout
- Re-calculate PRs after edits
- Show "Edited" indicator on edited workouts
- Consider storing edit history (optional)

**Files to Modify:**
- `Views/WorkoutHistoryDetailView.swift` - Add edit mode
- `ViewModels/HistoryViewModel.swift` - Add edit methods

---

### 🏃 Cardio-Specific Logging

**Status:** Partial (SetRecord has duration/distance fields, but UI doesn't use them)

**Description:**
- Better UI for cardio exercises (time/distance instead of weight/reps)
- Track pace, heart rate zones
- Calculate calories (estimate or from HealthKit)
- Different set UI for cardio vs. strength

**Implementation Notes:**
- Detect exercise category == .cardio
- Show different input fields in `SetRowView` (duration/distance vs. weight/reps)
- Optional: pace calculator, heart rate input
- Integration with HealthKit (see below)

**Files to Modify:**
- `Views/SetRowView.swift` - Conditional UI based on exercise type
- `ViewModels/ActiveWorkoutViewModel.swift` - Handle cardio-specific data

**Files to Create:**
- `Views/CardioSetRowView.swift` - Cardio-specific set input (optional)

---

### ⚙️ Settings Screen

**Status:** ✅ Complete (Basic Implementation)

**Description:**
- ✅ Default rest timer duration
- ✅ Units (lbs vs. kg)
- ✅ Theme preferences (Dark / Light / System)
- ✅ Clear all data option
- ⏳ Export data (JSON backup) - Future enhancement
- ⏳ Import data - Future enhancement
- ⏳ Notifications preferences - Future enhancement

**Implementation:**
- `Models/UserProfile.swift` - Profile model with preferences
- `ViewModels/ProfileViewModel.swift` - Settings management
- `Views/ProfileView.swift` - Profile display
- `Views/SettingsView.swift` - Settings UI

**Future Enhancements:**
- Export/import workout data as JSON
- Notifications preferences
- Additional settings options

---

## Lower Priority

### ⌚ Apple Watch App

**Status:** Partial (Watch target exists but minimal implementation)

**Description:**
- View active workout on Watch
- Control rest timer from Watch
- View workout history
- Start workouts from Watch
- Complications showing stats

**Implementation Notes:**
- Implement `FlowState Watch Watch App` target
- Share SwiftData model with iPhone app (via CloudKit sync)
- Watch-specific UI optimized for small screen
- Use Watch Connectivity for real-time sync

**Files to Modify:**
- `FlowState Watch Watch App/ContentView.swift` - Watch UI
- `FlowState Watch Watch App/FlowState_WatchApp.swift` - Watch app setup

**Files to Create:**
- Watch-specific views in Watch target

---

### 🏥 HealthKit Integration

**Status:** Not Started

**Description:**
- Sync workouts to Health app
- Import heart rate data from workouts
- Import active energy (calories) from workouts
- Read weight/body measurements
- Display HealthKit data in app

**Implementation Notes:**
- Request HealthKit permissions
- Read/write workout samples
- Sync `Workout` data to HealthKit workouts
- Read heart rate, active energy from HealthKit
- Privacy prompts and data handling

**Files to Create:**
- `ViewModels/HealthKitManager.swift` - HealthKit operations
- `Views/HealthKitPermissionView.swift` - Permission request
- HealthKit authorization in app lifecycle

---

## Nice to Have

### 📱 Widgets

**Description:** iOS home screen widgets showing workout stats, streaks, recent PRs

### 🔔 Workout Reminders

**Description:** Notifications reminding user to work out based on schedule

### 👥 Social Features

**Description:** Share workouts, compete with friends (low priority, may never implement)

### 📤 Export/Import

**Status:** Not Started

**Description:** 
- Export workout data as JSON/CSV
- Import/restore data from backup
- Backup/restore functionality

**Implementation Notes:**
- Export all workouts, exercises, templates, PRs
- JSON format for easy parsing
- Import validation and error handling
- Settings screen integration (placeholder already exists)

**Related Features:**
- Settings screen (export button placeholder exists)

### 🎨 Custom Themes

**Description:** More theme options beyond dark mode (low priority)

### 📝 Workout Notes Enhancement

**Description:** Rich text notes, photos, voice notes for workouts

### 🔍 Advanced Search

**Description:** Search workouts by exercise, date range, notes

### 📊 Advanced Analytics

**Description:** Volume progression, strength standards comparison, program tracking

---

## Technical Improvements

### Error Handling

**Status:** Partial (errors print to console, no user feedback)

**Description:**
- User-friendly error messages
- Retry mechanisms
- Offline mode handling
- Data validation feedback

### Performance Optimization

**Status:** Not Started

**Description:**
- Cache progress calculations
- Lazy load workout history
- Optimize SetRecord encoding/decoding
- Pagination for large datasets

### Testing

**Status:** Not Started

**Description:**
- Unit tests for ViewModels
- UI tests for critical flows
- Integration tests for data persistence

### Accessibility

**Status:** Partial (basic SwiftUI accessibility)

**Description:**
- VoiceOver improvements
- Dynamic Type support
- Color contrast improvements
- Custom accessibility labels

---

## Notes

- Features listed in priority order (High → Medium → Lower)
- Related features are grouped together
- Some features depend on others (e.g., PRs needed for progress charts)
- Priority may change based on user feedback
- Technical improvements can be done incrementally
