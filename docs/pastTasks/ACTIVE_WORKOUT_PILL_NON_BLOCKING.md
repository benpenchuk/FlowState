 # Active Workout Pill Non-Blocking
 
 ## Summary
 - Moved the floating workout pill into per-tab safe area insets so it no longer overlaps the tab bar and reserves layout space.
 - Tightened hit testing to the capsule shape and added quick actions for resume/rest/finish/cancel.
 - Hid the pill while the keyboard or non-workout modals are presented and improved accessibility labels/values.
 
 ## Key Files
 - `FlowState/ContentView.swift`
 - `FlowState/Views/FloatingWorkoutPill.swift`
 - `FlowState/Extensions/KeyboardObserver.swift`
 - `FlowState/Extensions/ModalPresentationObserver.swift`
 
 ## Implementation Notes
 - `ContentView` now wraps each tab root with `.safeAreaInset(edge: .bottom)` to place the pill above the tab bar.
 - `FloatingWorkoutPill` uses `contentShape(Capsule())`, a reduce-motion friendly transition, and context menu actions.
 - Keyboard visibility is tracked via `KeyboardObserver`.
 - Modal presentation state is tracked via `ModalPresentationObserver` to hide the pill during sheets.
 
 ## Test Notes
 - Not run (manual verification recommended: tab bar taps, keyboard show/hide, sheet presentation, VoiceOver).
