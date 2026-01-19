# Home Stats Improvements

**Date:** January 19, 2026  
**Status:** Completed

## Summary

Refactored the home stats section to improve performance, add time period selection, period comparison, better formatting, and loading states.

## Changes Made

### 1. Created HomeStatsViewModel (`FlowState/ViewModels/HomeStatsViewModel.swift`)

- **New ViewModel** following existing patterns (similar to ProgressViewModel)
- **Published properties** for reactive updates:
  - `workoutsCount`, `totalTime`, `currentStreak`
  - `previousWorkoutsCount`, `previousTotalTime` (for comparison)
  - `isLoading`, `selectedPeriod`
- **StatsPeriod enum** with 4 options:
  - This Week
  - Last 7 Days
  - This Month
  - Last 30 Days
- **Background processing**: Stats calculations run on background queue for better performance
- **Automatic refresh**: Stats recalculate when period selection changes

### 2. Created SkeletonStatsCard (`FlowState/Views/Skeletons/SkeletonStatsCard.swift`)

- Loading skeleton matching the stats card layout
- Shows placeholder UI while stats are being calculated
- Uses `.redacted(reason: .placeholder)` modifier for shimmer effect

### 3. Updated HomeView (`FlowState/Views/HomeView.swift`)

#### Removed:
- `WeeklyStatsData` struct (lines 29-33)
- `weeklyStats` state variable
- `calculateWeeklyStats()` method (lines 252-302)
- `calculateStreak()` method (lines 304-357)

#### Added:
- `@StateObject private var statsViewModel = HomeStatsViewModel()`
- Segmented picker for time period selection above stats card
- Loading state handling with SkeletonStatsCard
- Period comparison indicators (green/red arrows with diff)
- `StatItemView` helper component for stat display with comparison

#### Updated:
- Greeting text now dynamically shows selected period
- `formatTime()` function improved:
  - Shows "—" for zero time instead of "0m"
  - Shows both hours and minutes when applicable (e.g., "1h 23m")
- `.task` and `.onChange` modifiers to use statsViewModel

### 4. Added StatItemView Helper Component

- Displays stat value, label, and comparison indicator
- Shows green arrow for improvements, red arrow for declines
- Conditionally shows comparison only when previous value exists

## Architecture Improvements

### Before:
```
HomeView (View)
├── calculateWeeklyStats() - blocking main thread
├── calculateStreak() - blocking main thread
└── weeklyStats (local state)
```

### After:
```
HomeView (View)
└── HomeStatsViewModel (ObservableObject)
    ├── calculateStats() - async background processing
    ├── calculateStreak() - background processing
    └── Published properties - reactive updates
```

## Performance Optimizations

1. **Background Processing**: All database queries and calculations run on background queue
2. **MainActor Updates**: UI updates dispatched to main thread
3. **Automatic Caching**: Stats cached until period changes or workout completes
4. **Reduced Main Thread Work**: No blocking operations on main thread

## User Experience Improvements

1. **Time Period Selection**: Users can switch between 4 different time periods
2. **Period Comparison**: See how current period compares to previous period
3. **Loading States**: Skeleton UI shows while stats calculate
4. **Better Formatting**: 
   - "—" for empty states instead of "0m"
   - Hours and minutes shown together (e.g., "2h 45m")
5. **Dynamic Greeting**: Updates to reflect selected period

## Testing Instructions

### Manual Testing

1. **Launch App**: Open FlowState and navigate to Home tab
2. **Verify Default State**: 
   - Stats should show "This Week" by default
   - Loading skeleton should appear briefly on first load
   - Stats should display with proper formatting

3. **Test Period Selection**:
   - Tap "Last 7 Days" - stats should update
   - Tap "This Month" - stats should update
   - Tap "Last 30 Days" - stats should update
   - Each change should show loading skeleton briefly

4. **Test Period Comparison**:
   - If you have workouts from multiple weeks/months:
     - Should see green ↑ arrows for increases
     - Should see red ↓ arrows for decreases
   - If previous period has no data, no comparison shown

5. **Test Time Formatting**:
   - With 0 minutes: Should show "—"
   - With only minutes: Should show "45m"
   - With only hours: Should show "2h"
   - With both: Should show "2h 45m"

6. **Test Greeting Text**:
   - Should say "You've completed X workouts this week" (or selected period)
   - Should be singular "workout" when count is 1

7. **Test Workout Completion**:
   - Complete a workout
   - Return to home tab
   - Stats should automatically refresh

8. **Test Loading States**:
   - Switch tabs away and back
   - Should see skeleton loading briefly
   - Stats should update properly

### Edge Cases to Test

1. **No Workouts**: 
   - All stats should show 0 or "—"
   - No comparison indicators shown

2. **First Workout**:
   - Stats update correctly
   - Streak shows 1

3. **Period with No Data**:
   - Stats show "—" appropriately
   - No comparison shown

4. **Quick Period Switching**:
   - Rapidly switch periods
   - Should handle gracefully without crashes

## Known Limitations

1. **Streak Calculation**: Streak is always "current" and doesn't change based on selected period
2. **Comparison Baseline**: Previous period comparison uses same duration (e.g., "This Week" compares to last week, not last 7 days)

## Future Enhancements

- Add goal setting (e.g., "3/5 workouts this week")
- Add visual progress indicators or charts
- Make stats tappable to show detail view
- Add animation to number changes
- Add more stats (average duration, volume, etc.)
- Add all-time best streak display

## Files Modified

1. **New Files**:
   - `FlowState/ViewModels/HomeStatsViewModel.swift` (270 lines)
   - `FlowState/Views/Skeletons/SkeletonStatsCard.swift` (73 lines)

2. **Modified Files**:
   - `FlowState/Views/HomeView.swift` (removed ~150 lines, added ~100 lines)

## Total Impact

- **Net Code Change**: ~+293 lines (accounting for removals)
- **Files Changed**: 3 (2 new, 1 modified)
- **Performance**: Significant improvement - no main thread blocking
- **User Experience**: Much improved with period selection and comparison

## Deployment Notes

- No breaking changes
- No database migrations required
- Backward compatible with existing data
- Works with existing SwiftData models
