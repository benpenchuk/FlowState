# Drag Handle Location Issue

## Problem Statement

The drag handle functionality for reordering sets is split across two separate files, creating a separation of concerns issue that makes the code harder to maintain and understand.

### Current Architecture

The drag handle is split into two distinct parts:

1. **Visual Icon** - Located in `SetRowView.swift`
2. **Drag & Drop Logic** - Located in `ExerciseSectionView.swift`

This separation creates several problems:
- The visual indicator (drag handle icon) is disconnected from its functionality
- Developers must look in two different files to understand how drag-and-drop works
- Changes to the drag handle appearance require coordination across files
- The drag handle visual doesn't actually handle the drag interaction itself

## Current Implementation

### Visual Icon Location

**File:** `FlowState/Views/SetRowView.swift`  
**Lines:** 118-125

```swift
private var dragHandle: some View {
    Image(systemName: "line.3.horizontal")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary.opacity(0.4))
        .frame(width: 20, height: 44)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
}
```

**Placement:** The drag handle is placed at the very beginning of the `HStack` in the body (line 45).

### Drag & Drop Logic Location

**File:** `FlowState/Views/ExerciseSectionView.swift`

**`.onDrag` Modifier** (Lines 203-217):
```swift
.onDrag {
    draggedSetId = set.id
    currentDragId = set.id
    let uuidString = set.id.uuidString
    let itemProvider = NSItemProvider()
    itemProvider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
        completion(uuidString.data(using: .utf8), nil)
        return nil
    }
    return itemProvider
} preview: {
    SetRowView(viewModel: viewModel, set: set, preferredUnits: preferredUnits, onUpdate: { _, _, _, _ in }, onDelete: {}, onLabelUpdate: nil)
        .frame(width: 350)
        .background(Color(.systemBackground))
}
```

**`.onDrop` Modifier** (Line 218):
```swift
.onDrop(of: [.text], delegate: SetDropDelegate(
    destinationSet: set,
    sets: sets,
    entry: entry,
    viewModel: viewModel,
    draggedSetId: $draggedSetId,
    dropTargetSetId: $dropTargetSetId,
    currentDragId: $currentDragId
))
```

**`SetDropDelegate`** (Lines 407-442):
The delegate handles the actual reordering logic when a set is dropped.

## Issues with Current Approach

### 1. **Separation of Concerns Violation**
- The visual indicator and its functionality are in different files
- This violates the principle that related code should be co-located
- Makes it harder to understand the complete drag-and-drop flow

### 2. **Maintenance Burden**
- Changes to drag handle appearance require editing `SetRowView.swift`
- Changes to drag behavior require editing `ExerciseSectionView.swift`
- No single source of truth for drag handle functionality

### 3. **Discoverability**
- New developers might not realize the drag handle icon is interactive
- The `.onDrag` modifier is applied to the entire `SetRowView`, not just the handle
- The handle icon itself doesn't indicate it's draggable (no visual feedback on press)

### 4. **Accessibility**
- The drag handle is marked as `accessibilityHidden(true)`, which hides it from VoiceOver
- However, the drag functionality is still available, creating an inconsistent experience
- Users relying on accessibility features may not discover the drag functionality

### 5. **User Experience**
- The entire row is draggable, not just the handle icon
- This can cause accidental drags when users are trying to interact with other elements
- No visual feedback when hovering over the drag handle specifically

## Proposed Solutions

### Solution 1: Move Drag Logic to SetRowView

**Approach:** Encapsulate all drag handle functionality within `SetRowView`.

**Benefits:**
- Single source of truth for drag handle behavior
- Better encapsulation and cohesion
- Easier to test and maintain
- Clearer component boundaries

**Implementation:**
1. Move drag state management into `SetRowView`
2. Apply `.onDrag` modifier directly to the `dragHandle` view
3. Pass drop delegate and related state as parameters to `SetRowView`
4. Handle drag preview within `SetRowView`

**Challenges:**
- Need to pass additional parameters (sets array, entry, viewModel)
- Drop delegate still needs to be in parent view (or moved to ViewModel)
- May require refactoring of state management

### Solution 2: Create Dedicated DragHandle Component

**Approach:** Extract drag handle into its own reusable component.

**Benefits:**
- Reusable across different contexts
- Clear separation of drag handle UI and logic
- Can be tested independently

**Implementation:**
1. Create `DragHandleView` component
2. Include both visual and interaction logic
3. Accept callbacks for drag events
4. Use in both `SetRowView` and other places where drag is needed

**Challenges:**
- May be overkill for a single use case
- Adds another file to maintain
- Still need to coordinate with parent view for drop logic

### Solution 3: Apply Drag Only to Handle Icon

**Approach:** Keep current structure but apply `.onDrag` only to the handle icon.

**Benefits:**
- Minimal changes to existing code
- More intuitive UX (only handle is draggable)
- Better discoverability

**Implementation:**
1. Move `.onDrag` modifier from entire `SetRowView` to just `dragHandle`
2. Keep drop logic in parent view
3. Add visual feedback to handle (hover/press states)

**Challenges:**
- Still maintains separation between visual and logic
- May require gesture recognizer conflicts resolution
- Need to ensure handle is large enough for easy interaction

### Solution 4: Hybrid Approach - Handle in SetRowView, Drop in Parent

**Approach:** Move drag initiation to handle, keep drop logic in parent.

**Benefits:**
- Balances encapsulation with practical concerns
- Drag handle becomes self-contained
- Drop logic stays where it has access to all sets

**Implementation:**
1. Add drag state and `.onDrag` to `dragHandle` in `SetRowView`
2. Expose drag events via callback or binding
3. Keep `.onDrop` and `SetDropDelegate` in `ExerciseSectionView`
4. Coordinate state between components

## Recommended Solution: Solution 1 (Full Encapsulation)

### Implementation Plan

1. **Refactor SetRowView**
   - Add drag state variables (`@State private var isDragging: Bool`)
   - Apply `.onDrag` modifier to `dragHandle` view
   - Add drag preview configuration
   - Expose drag events via callback: `onDragStart: ((UUID) -> Void)?`

2. **Update ExerciseSectionView**
   - Remove `.onDrag` from `SetRowView` wrapper
   - Pass drag callbacks to `SetRowView`
   - Keep `.onDrop` and `SetDropDelegate` (they need access to all sets)

3. **Improve Visual Feedback**
   - Add visual state to drag handle (opacity change on press)
   - Consider adding haptic feedback
   - Make handle more prominent when draggable

4. **Accessibility Improvements**
   - Remove `accessibilityHidden(true)` or make it conditional
   - Add accessibility label: "Drag to reorder set"
   - Add accessibility hint explaining drag functionality

### Code Structure After Refactoring

**SetRowView.swift:**
```swift
struct SetRowView: View {
    // ... existing properties ...
    let onDragStart: ((UUID) -> Void)?
    
    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary.opacity(isDragging ? 0.6 : 0.4))
            .frame(width: 20, height: 44)
            .contentShape(Rectangle())
            .onDrag {
                isDragging = true
                onDragStart?(set.id)
                // ... drag provider setup ...
            } preview: {
                // ... preview configuration ...
            }
            .accessibilityLabel("Drag to reorder set")
            .accessibilityHint("Double tap and hold to drag this set to a new position")
    }
}
```

**ExerciseSectionView.swift:**
```swift
SetRowView(
    // ... existing parameters ...
    onDragStart: { setId in
        draggedSetId = setId
        currentDragId = setId
    }
)
.onDrop(of: [.text], delegate: SetDropDelegate(...))
```

## Testing Considerations

After implementing the fix, verify:

- [ ] Drag handle is visually distinct and discoverable
- [ ] Only the handle icon initiates drag (not entire row)
- [ ] Drag preview shows correctly
- [ ] Drop functionality works as expected
- [ ] Visual feedback during drag is clear
- [ ] Accessibility features work correctly
- [ ] No conflicts with other gestures (swipe actions, taps)
- [ ] Performance is acceptable during drag operations

## Migration Path

1. **Phase 1:** Implement Solution 3 (quick win - apply drag only to handle)
2. **Phase 2:** Refactor to Solution 1 (full encapsulation)
3. **Phase 3:** Add visual improvements and accessibility enhancements

## Related Files

- `FlowState/Views/SetRowView.swift` - Visual drag handle
- `FlowState/Views/ExerciseSectionView.swift` - Drag & drop logic
- `FlowState/ViewModels/ActiveWorkoutViewModel.swift` - Reordering logic
- `docs/DRAG_DROP_SETS_FIX.md` - Previous drag-and-drop implementation notes

## Date

Documented: January 2025  
Issue Identified: During code review of drag-and-drop implementation
