# Scroll Tracking Fix - Active Workout Header

## Problem
The dynamic header on the active workout page (switching between full and compact timer displays based on scroll position) was not working. The `scrollOffset` state variable was not updating despite the `GeometryReader` correctly reporting scroll positions.

## Root Cause
The issue was in the `ScrollOffsetPreferenceKey.reduce` function. When SwiftUI collects preferences from multiple views in the view hierarchy, it calls `reduce` multiple times. Sometimes `nextValue()` returns `0.0` (the default value), which was overwriting actual scroll offsets that had already been accumulated.

**Original (broken) code:**
```swift
static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()  // ❌ This overwrites with 0.0 when nextValue() is default
}
```

## Solution
Modified the `reduce` function to only update `value` when `newValue` is non-zero:

```swift
static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    let newValue = nextValue()
    // Use newValue only if it's not the default (0), otherwise keep existing value
    // This prevents default values from overwriting actual scroll positions
    if abs(newValue) > 0.001 {
        value = newValue
    }
}
```

## How It Works
- When the user scrolls, the `GeometryReader` reports negative `minY` values (e.g., -11.0, -24.0, -49.33).
- These values are collected via the `PreferenceKey` system.
- During preference reduction, if `nextValue()` returns `0.0` (default), the function now preserves the existing non-zero value instead of overwriting it.
- This ensures the actual scroll offset is maintained and `scrollOffset` state updates correctly.
- The header conditionally switches between `fullHeaderView` and `compactPillsView` when `scrollOffset < 50`.

## Implementation Location
- **File**: `FlowState/Views/ActiveWorkoutFullScreenView.swift`
- **Struct**: `ScrollOffsetPreferenceKey`
- **Method**: `static func reduce(value:inout CGFloat, nextValue: () -> CGFloat)`

## Key Takeaway
When implementing `PreferenceKey.reduce`, always check if the new value is meaningful (non-default) before overwriting the accumulated value. Default values can be returned during SwiftUI's preference collection process and should be ignored when they would discard actual data.
