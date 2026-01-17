# Drag and Drop Sets Implementation Reference

## Problem Statement

Implementing drag-and-drop for reordering sets within an exercise had several issues:
1. **Sets became too small when dragged** - The drag preview was compressed/minimized
2. **Sets couldn't be moved when dragged down** - Destination index calculation was incorrect
3. **Sets stayed dark/opaque after drag** - Visual state wasn't cleared when drag was cancelled
4. **Couldn't move to last position** - Special case for moving to the end wasn't handled

## Root Causes

### 1. Drag Preview Size
- SwiftUI's default drag preview compresses views
- Custom preview needed to maintain full size

### 2. Async Data Loading
- `NSItemProvider.loadItem()` is async and unreliable
- Completion handler often doesn't fire or fires too late
- Solution: Use synchronous state tracking via `@State` variable

### 3. Index Calculation for `move(fromOffsets:toOffset:)`
- `toOffset` is the index BEFORE which to insert (measured from original array)
- When moving down to last position, need to use `sets.count` (after last item)
- When moving within array, use `destinationIndex` directly

### 4. State Management
- `draggedSetId` needs to be cleared both on drop AND on drag cancellation
- SwiftUI doesn't provide direct drag cancellation callback
- Solution: Use timeout to detect cancelled drags

## Implementation Details

### Key Files Modified

1. **`FlowState/Views/ActiveWorkoutView.swift`**
   - `ExerciseSectionView` - Added drag/drop state and handlers
   - `SetDropDelegate` - Drop delegate for handling reordering

2. **`FlowState/ViewModels/ActiveWorkoutViewModel.swift`**
   - `reorderSets()` - Logic for reordering sets array

### State Variables

```swift
@State private var draggedSetId: UUID? = nil      // For visual feedback (opacity)
@State private var dropTargetSetId: UUID? = nil    // For drop target highlight
@State private var currentDragId: UUID? = nil      // For synchronous drag tracking
```

### Drag Implementation

```swift
.onDrag {
    draggedSetId = set.id
    currentDragId = set.id
    
    // Timeout to clear state if drag is cancelled
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        if draggedSetId == set.id && dropTargetSetId == nil {
            draggedSetId = nil
            currentDragId = nil
        }
    }
    
    // Item provider for data transfer
    let itemProvider = NSItemProvider()
    itemProvider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
        let data = set.id.uuidString.data(using: .utf8) ?? Data()
        completion(data, nil)
        return nil
    }
    return itemProvider
} preview: {
    // Custom preview to maintain full size
    SetRowView(set: set, ...)
        .frame(width: 350)
        .background(Color(.systemBackground))
}
```

### Drop Delegate Implementation

Key pattern: **Use synchronous state first, fallback to async loading**

```swift
func dropEntered(info: DropInfo) {
    // Prefer synchronous currentDragId
    if let sourceId = currentDragId {
        performReorder(sourceId: sourceId, showFeedback: true)
    } else {
        // Fallback to async loading (less reliable)
        loadAndReorder(info: info, showFeedback: true)
    }
}
```

### Index Calculation Logic

**Critical:** Understanding `move(fromOffsets:toOffset:)`:

- `toOffset` is the index **BEFORE** which to insert (in original array)
- For moving within array: use `destinationIndex`
- For moving to **last position**: use `sets.count` (after last item)

```swift
let adjustedDestination: Int
if sourceIndex < destinationIndex && destinationIndex == sets.count - 1 {
    // Moving down to the last position - insert AFTER last item
    adjustedDestination = sets.count
} else {
    // Normal case - insert before destination
    adjustedDestination = destinationIndex
}
```

### Visual Feedback

1. **Dragged item**: Reduce opacity to 0.5
```swift
.opacity(draggedSetId == set.id ? 0.5 : 1.0)
```

2. **Drop target**: Show orange border
```swift
.overlay(
    Group {
        if dropTargetSetId == set.id && draggedSetId != set.id {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 2)
                .padding(-4)
        }
    }
)
```

## Debug Logging Pattern

Comprehensive logging at each step helps diagnose issues:

```
🟢 DRAG STARTED - When drag begins
🔵 DROP VALIDATE - When drop is validated
🟠 DROP ENTERED - When entering drop zone
🔴 DROP EXITED - When exiting drop zone
🟡 DROP PERFORMED - When drop completes
🔄 REORDERING - When reorder operation happens
✅ Success indicators
🔴 Error indicators
⚠️ Warning indicators (e.g., source == destination)
```

## Common Pitfalls

### 1. Async Data Loading
- **Problem**: `loadItem()` completion handler is unreliable
- **Solution**: Use synchronous `currentDragId` state variable set in `onDrag`

### 2. Index Calculation
- **Problem**: Confusion about `toOffset` parameter meaning
- **Solution**: Remember it's "before this index" in original array. For last position, use `count`.

### 3. State Cleanup
- **Problem**: State persists after cancelled drags
- **Solution**: Use timeout in `onDrag` to detect cancellations

### 4. Visual Feedback Timing
- **Problem**: Feedback appears/disappears at wrong times
- **Solution**: Clear `dropTargetSetId` in both `dropExited` and `performDrop`

## Testing Checklist

- [ ] Drag set up (should move)
- [ ] Drag set down (should move)
- [ ] Drag set to last position (should work)
- [ ] Drag set to first position (should work)
- [ ] Cancel drag by releasing outside (state should clear)
- [ ] Visual feedback (opacity) during drag
- [ ] Visual feedback (border) on drop targets
- [ ] Multiple rapid drags (should work correctly)

## Example Log Output (Working)

```
🟢 DRAG STARTED - Set ID: ABC..., Set Number: 2
🔵 DROP VALIDATE - Destination Set: 3
🟠 DROP ENTERED - Destination Set: 3
🟠 Using currentDragId immediately: ABC...
✅ INDICES FOUND - Source: 1, Destination: 2
🔄 REORDERING - From index 1 to index 2
✅ Sets reordered and saved successfully
🟡 DROP PERFORMED - Destination Set: 3
```

## Future Improvements

1. **Debouncing**: Prevent multiple reorders during rapid drag movements
2. **Animation**: Add smooth animations during reordering
3. **Haptic Feedback**: Add haptic feedback on successful drop
4. **Accessibility**: Improve VoiceOver support for drag operations

## References

- SwiftUI `onDrag` documentation
- `move(fromOffsets:toOffset:)` array method behavior
- `NSItemProvider` data transfer patterns
- SwiftUI drag-and-drop best practices

## Date

Documented: January 2025
Last Updated: After fixing drag-and-drop implementation issues
