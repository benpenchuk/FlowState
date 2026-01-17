# Live Activity Research for Rest Timer

## Executive Summary

Live Activities are a powerful iOS feature (introduced in iOS 16.1) that allows apps to display real-time, dynamic content on system surfaces like the Lock Screen, Dynamic Island, StandBy, and Apple Watch Smart Stack. They are designed for time-bound, transactional content and can continue functioning even when the app is backgrounded or killed, making them potentially suitable for a rest timer.

However, implementing Live Activities requires significant architectural changes including a Widget Extension target, ActivityKit framework integration, and careful consideration of system limitations.

## What Are Live Activities?

### Core Concept
- **Dynamic Display Surfaces**: Lock Screen, Dynamic Island (iPhone), StandBy (iPhone), Apple Watch Smart Stack, macOS menu bar (via iPhone Mirroring), CarPlay
- **Real-time Updates**: Content can be updated locally via ActivityKit or remotely via push notifications
- **Background Persistence**: Can continue running when app is not active
- **User Interaction**: Tappable to launch app or deep-link to specific content

### Key Differentiators from Notifications
- **Persistent Visibility**: Remain visible on Lock Screen until dismissed or expired
- **Real-time Updates**: Content updates without user interaction
- **Rich UI**: Full SwiftUI views with animations and interactive elements
- **System Integration**: Native to iOS system surfaces, not overlay notifications

### iOS Version Requirements
- **Minimum**: iOS 16.1 (released October 2022)
- **Recommended**: iOS 16.2+ for improved APIs
- **iPadOS**: iPadOS 17+ for full support
- **Apple Watch**: watchOS 11+ with iOS 18+ for Smart Stack integration

## Technical Requirements

### Frameworks
- **ActivityKit**: Core framework for managing Live Activity lifecycle
- **WidgetKit**: For building the Live Activity UI (SwiftUI-based)
- **SwiftUI**: UI framework for Live Activity views

### Xcode Project Setup
- **Widget Extension Target**: Required - must be created with "Include Live Activity" option
- **Info.plist Entries**:
  - `NSSupportsLiveActivities`: Boolean = YES (required)
  - `NSSupportsLiveActivitiesFrequentUpdates`: Boolean = YES (optional, for higher update frequency budget)

### Entitlements
- No special entitlements required for basic Live Activities
- APNs certificates needed if using push-to-start/update functionality

### Push Notification Setup (for remote updates)
- `.p8` authentication key (certificate-based `.p12` not supported)
- `liveactivity` push type for remote updates
- Server-side infrastructure to send push notifications

## Architecture Overview

### ActivityAttributes Structure
```swift
struct RestTimerAttributes: ActivityAttributes {
    // Static data (unchanged during activity lifetime)
    var exerciseName: String
    var totalDuration: TimeInterval
    var startTime: Date

    // Dynamic data (updated during activity)
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var isPaused: Bool
        var currentSet: Int
        var totalSets: Int
    }
}
```

### Widget Extension Structure
```swift
@main
struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen / Banner view
            RestTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island views (compact, minimal, expanded)
            DynamicIsland {
                // Expanded state regions
                DynamicIslandExpandedRegion(.leading) { /* content */ }
                DynamicIslandExpandedRegion(.trailing) { /* content */ }
                DynamicIslandExpandedRegion(.center) { /* content */ }
                DynamicIslandExpandedRegion(.bottom) { /* content */ }
            } compactLeading: {
                // Compact state leading content
            } compactTrailing: {
                // Compact state trailing content
            } minimal: {
                // Minimal state content
            }
        }
    }
}
```

### Lifecycle Management
```swift
// Starting an activity
let attributes = RestTimerAttributes(exerciseName: "Bench Press", ...)
let initialState = RestTimerAttributes.ContentState(remainingTime: 60, ...)
let activity = try Activity<RestTimerAttributes>.request(
    attributes: attributes,
    content: ActivityContent(state: initialState, staleDate: nil),
    pushType: nil
)

// Updating during timer countdown
let updatedState = RestTimerAttributes.ContentState(remainingTime: 45, ...)
await activity.update(content: ActivityContent(state: updatedState, staleDate: nil))

// Ending the activity
await activity.end(
    content: ActivityContent(state: finalState, staleDate: nil),
    dismissalPolicy: .immediate
)
```

## Implementation Steps

### Phase 1: Project Setup
1. Create Widget Extension target with Live Activity support
2. Add `NSSupportsLiveActivities = YES` to main app Info.plist
3. Import ActivityKit framework
4. Define ActivityAttributes struct in shared code

### Phase 2: UI Design
1. Design Lock Screen layout (portrait orientation, glanceable)
2. Design Dynamic Island states:
   - **Compact**: Leading + trailing content for single activity
   - **Minimal**: Icon-only for multiple activities
   - **Expanded**: Full detail with regions (leading, center, trailing, bottom)
3. Implement SwiftUI views for each presentation
4. Add deep-linking support with `widgetURL()`

### Phase 3: Integration
1. Modify RestTimerViewModel to manage Live Activity lifecycle
2. Add ActivityKit calls for start/update/end operations
3. Handle app state changes (background/foreground transitions)
4. Implement timer state synchronization

### Phase 4: Push Notifications (Optional)
1. Set up APNs with `.p8` key
2. Implement server-side push notification sending
3. Handle push-to-start and push-to-update scenarios
4. Test background update functionality

### Phase 5: Testing & Refinement
1. Test all presentation modes (Lock Screen, Dynamic Island states)
2. Test background/foreground transitions
3. Test activity dismissal and cleanup
4. Performance testing for update frequency

## Known Limitations & Constraints

### Duration Limits
- **Active Duration**: Maximum 8 hours before automatic termination
- **Post-End Visibility**: Up to 4 hours after ending before removal
- **Total Lifespan**: Maximum 12 hours from start to complete removal

### Update Frequency
- **iOS 17 and earlier**: Could update ~every second
- **iOS 18+**: Limited to every 5-15 seconds (to prevent NAND wear)
- **Push Notifications**: Subject to system throttling/budget limits
- **Background Updates**: Only via push notifications when app is killed

### Data Size Constraints
- **Dynamic Content**: 4KB limit per update (including push payload)
- **Images**: Must fit presentation size, oversized images rejected
- **Static Data**: Included in 4KB limit

### Platform Limitations
- **iPad**: Limited support (iPadOS 17+ only)
- **Apple Watch**: Requires watchOS 11+ and iOS 18+
- **macOS**: Via iPhone Mirroring (iOS 18+)
- **CarPlay**: iOS 26+ integration

### Background Execution
- **When Backgrounded**: Local updates possible via ActivityKit
- **When Killed**: Only remote updates via push notifications
- **No Code Execution**: App code cannot run when terminated
- **Timer Management**: Must rely on system-provided timer views or push updates

### User Experience Considerations
- **Privacy**: Content visible on Lock Screen - avoid sensitive data
- **Battery Impact**: Frequent updates consume battery
- **System Resources**: Limited by iOS resource management
- **User Control**: Users can disable Live Activities in Settings

## Feasibility Assessment for Rest Timer

### Technical Feasibility: HIGH ✅
- Timer functionality aligns well with Live Activity use cases
- Background persistence solves the core problem of timer visibility when app is not active
- SwiftUI integration fits existing codebase architecture

### Implementation Complexity: HIGH ⚠️
- Requires Widget Extension target (significant project restructuring)
- Need to manage dual codebases (app + extension)
- Push notification infrastructure needed for full background support
- Multiple UI states to design and maintain

### User Experience Value: MEDIUM-HIGH ✅
- **Lock Screen Visibility**: Users can see timer progress without unlocking
- **Dynamic Island Integration**: Quick glance access during workouts
- **Background Persistence**: Timer continues when phone locked or app backgrounded
- **Deep Linking**: Tap to return to timer immediately

### System Limitations Impact: MEDIUM ⚠️
- **Update Frequency**: 5-15 second limit may make countdown feel "jerky"
- **Duration Limit**: 8-hour maximum may not cover ultra-long rest periods
- **iOS Version**: Requires iOS 16.1+ (excludes ~15% of active devices)
- **Push Dependency**: Full functionality requires server-side push infrastructure

### Development Effort Estimate
- **Basic Implementation**: 2-3 weeks (local updates only)
- **Full Implementation**: 4-6 weeks (including push notifications)
- **Testing**: 1-2 weeks (various device states and iOS versions)
- **Maintenance**: Ongoing (multiple UI variants, system compatibility)

### Recommended Approach
1. **Start with local-only implementation** (no push notifications)
2. **Use system timer views** for smooth countdown animation
3. **Implement basic Lock Screen + Dynamic Island UI**
4. **Test thoroughly** before adding push notification complexity
5. **Consider fallback** for devices below iOS 16.1

### Alternative Considerations
If Live Activities prove too complex, consider:
- **Persistent Notifications**: Standard notifications with progress
- **Widgets**: Home Screen widgets for timer status
- **App Clips**: Quick timer access without full app launch
- **Watch App**: Native watchOS timer integration

## Conclusion

Live Activities are **technically feasible** for a rest timer and would provide significant user experience value, particularly for background timer visibility. However, the implementation requires substantial architectural changes and careful consideration of system limitations.

**Recommendation**: Proceed with implementation but start with a minimal viable version focusing on local updates and core UI states. The push notification infrastructure can be added as a future enhancement if the basic functionality proves valuable.

**Key Decision Factors**:
- Target user iOS distribution (16.1+ adoption rate)
- Willingness to maintain Widget Extension complexity
- Importance of background timer persistence vs. implementation effort
- Available development resources for multi-target maintenance