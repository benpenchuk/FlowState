## Summary

The Exercises tab was simplified into a **pure exercise library** with a **stable, predictable header** and a **flat A–Z list** (no “Favorites” section and no category/muscle-group sections).

This improves scan speed in gym lighting, reduces visual “chrome” in the header, and makes the screen feel like raw searchable/filterable data.

## Why

- **Header felt broken/unstable**: large-title + searchable + pinned custom header created awkward spacing and overlap while scrolling.
- **Sections + Favorites were adding structure we didn’t want**: the goal shifted to a “raw library” feel instead of curated lists.
- **Default behavior should be simple**: show everything and sort **A–Z**, then let search/chips narrow results.

## UX Behavior (current)

- **Navigation title**: Uses inline title mode for stable nav/search layout.
- **Search**: `.searchable` remains and searches across all exercises (strength + cardio).
- **Pinned filter pills**: Filter bar stays pinned at the top of the list content.
- **List**:
  - **Single flat list** sorted A–Z by exercise name.
  - No category headers.
  - No separate Favorites section.
- **Filtering pipeline** (in-memory):
  - search → muscle group → equipment → favoritesOnly → customOnly

Notes:
- Muscle group chips naturally narrow to strength categories (since cardio categories won’t match “Chest/Back/etc”).
- Cardio exercises remain visible by default when no muscle chip is selected.

## Implementation Details

### Header stabilization

- Forced **inline** title display to avoid large-title blank space interactions with the pinned header.
- Simplified the top inset header so only one view owns the background and spacing.

### Flat A–Z list

- Removed category/grouping logic and any header sections.
- Removed “Favorites” section entirely.
- List is derived from the filtered set and then sorted by localized case-insensitive A–Z.

## Files changed

- `FlowState/Views/ExerciseListView.swift`
  - Header cleanup: inline title mode + simplified pinned filter bar container
  - Display: flat A–Z list (no sections/favorites)
  - Filtering pipeline no longer depends on a strength/cardio segmented control
- `FlowState/Views/ExerciseFilterBar.swift`
  - Removed redundant background so the pinned container owns layout/background cleanly

## Follow-ups (optional)

- Add a lightweight empty state when filters result in zero matches (“No results”).
- Consider a single “Clear filters” affordance when any chip/toggle is active.

