# Known Issues & Future Refinements

This document tracks known issues, UI/UX improvements needed, and future enhancements for the FlowState app.

## UI/UX Polish Needed

### Set Row Spacing & Sizing
- **Issue**: Set row spacing/sizing feels too large/spacious
- **Details**: 
  - May need to reduce padding and row heights slightly
  - Card backgrounds might be too prominent
  - Overall layout works but needs visual refinement
- **Priority**: Medium
- **Status**: Open

### Card Backgrounds
- **Issue**: Card backgrounds might be too prominent/visible
- **Details**: Consider reducing opacity or using more subtle backgrounds
- **Priority**: Low
- **Status**: Open

### Visual Refinement
- **Issue**: Overall layout works but needs visual refinement
- **Details**: General polish pass needed across active workout views
- **Priority**: Low
- **Status**: Open

## Bugs to Fix

### SwiftData Predicate Error
- **Issue**: Error calculating weekly stats with SwiftData
- **Error**: `SwiftDataError(_error: SwiftData.SwiftDataError._Error.unsupportedPredicate, _explanation: Optional("Unsupported Predicate: The \'Foundation.PredicateExpressions.ForcedUnwrap\' operator is not supported"))`
- **Location**: Weekly stats calculation
- **Priority**: Medium
- **Status**: Open
- **Notes**: Related to using forced unwrap (`!`) in SwiftData predicates

### Drag and Drop State Cleanup
- **Issue**: Drag state sometimes persists after drag is cancelled (minor issue)
- **Details**: Set opacity can stay at 0.5 after drag is cancelled without drop
- **Priority**: Low
- **Status**: Partially Fixed (has timeout fallback)
- **Notes**: Current implementation has 2-second timeout to clear state

### Active Workout Scroll & Timer Pill Transition
- **Issue**: Scrolling up in active workout causes buggy timer-to-pill transitions near the top
- **Details**: The transition from full-screen timers to floating pills is not smooth when scrolling close to the top of the workout view
- **Priority**: Medium
- **Status**: Open
- **Notes**: Complex scrolling animation issue requiring investigation of scroll position detection and transition logic

## Performance Issues

None currently identified.

## Future Refinements

### Exercise Instructions/Tips Viewer
- **Status**: ✅ Complete - Accessible from active workout via info button
- **Implementation**: Modal sheet showing exercise details during workout

### Exercise History Viewer
- **Status**: ✅ Complete - Quick history view during active workout
- **Implementation**: Modal sheet showing recent performance history

### Drag and Drop Enhancements
- **Enhancement**: Debounce rapid drag movements to prevent excessive reorders
- **Enhancement**: Add smooth animations during reordering
- **Enhancement**: Add haptic feedback on successful drop
- **Enhancement**: Improve VoiceOver support for drag operations

### Workout Flow Improvements
- **Enhancement**: Better visual feedback during set completion
- **Enhancement**: Quick weight suggestions based on previous workouts
- **Enhancement**: Exercise substitution suggestions

### Chart Enhancements
- **Enhancement**: Filter charts by time period (week, month, 3 months, year, all time)
- **Enhancement**: Support different metrics (1RM, volume, max weight, average weight)

### Home Dashboard
- **Enhancement**: Show workout streaks (consecutive days)
- **Enhancement**: Weekly summary (workouts completed, total sets, total volume)
- **Enhancement**: Recent PRs section

## Documentation

- All known issues should be documented here before filing as bugs
- Status should be updated as issues are resolved
- Priority: High, Medium, Low

---

**Last Updated**: January 2025
