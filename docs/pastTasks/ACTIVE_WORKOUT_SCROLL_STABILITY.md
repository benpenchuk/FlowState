# Active Workout Scroll Stability

**Date:** January 24, 2026  
**Status:** Completed

## Summary
Fixed a “glitchy” feel in the Active Workout screen when:
- The content fits on a single screen (no real scrolling) but the user still swipes heavily
- The user flings from top → bottom (or bottom → top) and the header transitions mid-momentum

The end result is a much more **Twitter/Instagram-like** scroll surface: always swipeable, smooth, and stable.

## Problem
The Active Workout view uses a scroll-position-driven header that switches between:
- a **full** header, and
- **compact pills**

When a heavy swipe caused the header to switch **while the ScrollView was still decelerating**, the header height changed mid-momentum. That produced a visible “jolt” / “glitch” during fast scrolls.

This was especially noticeable when:
- content was short (1-screen) but bounce interactions were frequent, and
- content size changed (collapsing exercises), causing the scroll position to clamp back to top/bottom.

## Root Causes

### 1) `PreferenceKey` logic conflated “no value” with a real `0.0`
The prior scroll offset tracker ignored `0.0` to avoid preference overwrites. That prevented the system from ever cleanly returning to a true “at top” state after content shrank.

### 2) Header layout changed during momentum scrolling
Header switching was directly tied to the continuously updating `scrollOffset` stream. During a strong swipe, crossing the threshold caused a header height change mid-deceleration → perceived glitch.

### 3) Bounce behavior didn’t match desired UX for 1-screen content
When content fit on one screen, the ScrollView didn’t always provide the familiar “always swipeable” surface feel.

## What Changed

### 1) Scroll offset PreferenceKey now accepts a real `0.0`
`ScrollOffsetPreferenceKey` was updated to use an optional value (default `nil`) so:
- `nil` means “no meaningful value emitted”
- `0.0` is treated as a real scroll position

### 2) Header transitions are debounced (no mid-momentum height changes)
Instead of switching header state immediately on every `scrollOffset` update, the header transition is now **debounced** (\(~120ms\)).

Effect:
- While the user is actively scrolling / decelerating, header state stays stable.
- Once scrolling “settles”, the header state updates if needed.

This removes the momentary layout shift that previously felt like a jolt.

### 3) Bounce is always enabled for a “Twitter-like” feel
The ScrollView uses:
- `.scrollBounceBehavior(.always)`

This makes the page feel swipeable even when content fits on one screen.

### 4) Small bottom buffer added
Added a small bottom padding buffer inside scroll content to reduce “hard bottom” interactions and to make the end of the content feel less abrupt.

### 5) Debug instrumentation (temporary, removed after verification)
During development, added:
- a small on-screen overlay (minY/offset/header) in top-right corner
- OSLog debug lines for scroll and header state transitions

These were used to verify that **header transitions no longer occur mid-swipe**. After successful verification, all debug instrumentation was removed from the production code.

## Files Changed
- `FlowState/Views/ActiveWorkoutFullScreenView.swift`
  - Optional scroll preference value
  - Debounced header state updates
  - `.scrollBounceBehavior(.always)`
  - Bottom content buffer
  - Removed `OSLog` import and all debug instrumentation after verification
- `FlowState/Views/ActiveWorkoutLayout.swift`
  - `headerCollapseThreshold`
  - `headerExpandThreshold`
  - `bottomScrollBuffer`

## Verification Notes
Manual verification confirmed:
- Heavy swipe top → bottom no longer produces the “glitch”
- Scroll surface feels consistently swipeable even with 1-screen content
- No mid-momentum `headerTransition` logs (header changes occur only after the scroll settles)

## Follow-ups / Related Notes
- Console warning observed during testing:
  - `SwiftData.ModelContext: Unbinding from the main queue... ModelContexts are not Sendable...`
  - This appears unrelated to scroll behavior but should be addressed separately (ModelActor / main-actor usage).

