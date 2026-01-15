# Coding Conventions

Conventions and patterns used in this codebase for consistency.

## File Organization

### Folder Structure

```
FlowState/
├── Models/          # SwiftData models and data structures only
├── ViewModels/      # Business logic and state management only
├── Views/           # SwiftUI views only
├── FlowStateApp.swift  # App entry point
└── Assets.xcassets/ # App resources
```

**Rules:**
- One file per model/ViewModel/view (when possible)
- Group related views in same file if small (e.g., `HistoricalSetRowView` in `WorkoutHistoryDetailView.swift`)
- Keep folder structure flat (no subfolders within Models/ViewModels/Views)

---

## Naming Conventions

### Files

- **Models:** `ModelName.swift` (e.g., `Exercise.swift`, `WorkoutEntry.swift`)
- **ViewModels:** `FeatureViewModel.swift` (e.g., `ActiveWorkoutViewModel.swift`, `HistoryViewModel.swift`)
- **Views:** `ViewName.swift` (e.g., `HomeView.swift`, `ActiveWorkoutView.swift`)
- Use PascalCase for all file names

### Classes, Structs, Enums

- **SwiftData Models:** PascalCase, singular (e.g., `Exercise`, `Workout`, `WorkoutEntry`)
- **ViewModels:** PascalCase with "ViewModel" suffix (e.g., `ActiveWorkoutViewModel`)
- **Views:** PascalCase with "View" suffix (e.g., `HomeView`, `ActiveWorkoutView`)
- **Enums:** PascalCase, singular (e.g., `ExerciseCategory`)

### Variables and Properties

- **Instance Variables:** camelCase (e.g., `activeWorkout`, `completedWorkouts`)
- **Published Properties:** camelCase with `@Published` (e.g., `@Published var activeWorkout: Workout?`)
- **State Variables:** camelCase with `@State` (e.g., `@State private var showingSheet = false`)
- **Constants:** camelCase or PascalCase depending on scope (local: camelCase, global: PascalCase)

### Functions

- **Methods:** camelCase, verb-based (e.g., `startWorkout()`, `finishWorkout()`, `fetchCompletedWorkouts()`)
- **Helper Functions:** camelCase, descriptive (e.g., `formatDuration()`, `calculateDuration()`)
- **Private Methods:** camelCase, prefix with descriptive verb (e.g., `loadActiveWorkout()`, `updateElapsedTime()`)

### View Components

- **Subviews:** PascalCase with descriptive name (e.g., `ExerciseSectionView`, `SetRowView`, `FloatingWorkoutPill`)
- Use descriptive names, not abbreviations (e.g., `FloatingWorkoutPill`, not `FloatingPill`)

---

## SwiftData Patterns

### Model Definition

```swift
@Model
final class ModelName {
    var id: UUID
    var property: Type
    @Relationship(deleteRule: .cascade) var relatedModels: [RelatedModel]?
    
    init(id: UUID = UUID(), property: Type, ...) {
        self.id = id
        self.property = property
    }
}
```

**Rules:**
- Always include `id: UUID` as first property
- Use `@Relationship` for related models
- Provide default `UUID()` in initializer
- Make models `final` when possible

### Querying Data

```swift
let descriptor = FetchDescriptor<Model>(
    predicate: #Predicate<Model> { model in
        model.property == value
    },
    sortBy: [SortDescriptor(\.property, order: .reverse)]
)

do {
    let results = try modelContext.fetch(descriptor)
    // Use results
} catch {
    print("Error fetching: \(error)")
}
```

**Rules:**
- Always use `do-catch` for SwiftData operations
- Print errors (no UI error handling yet)
- Use `#Predicate` macro for filtering
- Use `SortDescriptor` for sorting

### Saving Data

```swift
do {
    try modelContext.save()
} catch {
    print("Error saving: \(error)")
}
```

**Rules:**
- Always wrap in `do-catch`
- Print errors for debugging
- Call `save()` after mutations

---

## ViewModel Patterns

### Initialization

```swift
final class FeatureViewModel: ObservableObject {
    @Published var data: [Model] = []
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    private func loadData() {
        guard let modelContext = modelContext else { return }
        // Load data
    }
}
```

**Rules:**
- Use `setModelContext()` pattern (not constructor injection)
- Don't hold strong reference to context (avoid retain cycles)
- Load data in `setModelContext()` or dedicated `loadData()` method
- Guard against nil `modelContext`

### Published Properties

```swift
@Published var data: [Model] = []
@Published var isLoading: Bool = false
@Published var searchText: String = ""
```

**Rules:**
- Use `@Published` for properties that trigger UI updates
- Initialize with default values
- Use optionals when value may be nil

### Error Handling

```swift
do {
    try modelContext.save()
} catch {
    print("Error saving: \(error)")
    // No UI feedback yet
}
```

**Rules:**
- Print errors for debugging
- No user-facing error messages yet (TODO)
- Fail silently if operation is not critical

---

## SwiftUI View Patterns

### View Structure

```swift
struct FeatureView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FeatureViewModel()
    @State private var showingSheet = false
    
    var body: some View {
        // View content
    }
    
    private var computedView: some View {
        // Computed subviews
    }
    
    private func helperFunction() {
        // Helper functions
    }
}
```

**Rules:**
- Environment values first (`@Environment`)
- StateObject or ObservedObject ViewModels
- State variables for local UI state
- Computed properties for subviews (private)
- Helper functions for logic (private)

### Sheet Presentation

```swift
.sheet(isPresented: $showingSheet) {
    ChildView(viewModel: viewModel)
}
```

**Rules:**
- Use `@State` for sheet presentation state
- Use descriptive boolean names (`showingSheet`, `isPresented`, etc.)

### Navigation

```swift
NavigationLink {
    DetailView(item: item)
} label: {
    ItemRowView(item: item)
}
```

**Rules:**
- Use `NavigationLink` for drill-down navigation
- Use `sheet` for modals/forms
- Use `fullScreenCover` for immersive experiences

---

## SetRecord Pattern

### Encoding/Decoding

```swift
// In WorkoutEntry
func getSets() -> [SetRecord] {
    guard let data = setsData,
          let decoded = try? JSONDecoder().decode([SetRecord].self, from: data) else {
        return []
    }
    return decoded
}

func setSets(_ sets: [SetRecord]) {
    setsData = try? JSONEncoder().encode(sets)
}
```

**Rules:**
- Always use helper methods (`getSets()`, `setSets()`)
- Never access `setsData` directly
- Handle decoding errors gracefully (return empty array)
- Encoding errors are ignored (via `try?`)

### Updating Sets

```swift
var sets = entry.getSets()
if let index = sets.firstIndex(where: { $0.id == set.id }) {
    sets[index].weight = newWeight
    entry.setSets(sets)
    try? modelContext.save()
}
```

**Rules:**
- Get sets array, modify, save back
- Always save via `setSets()`, then `modelContext.save()`
- Find sets by `id`, not index (when possible)

---

## EnvironmentObject Pattern

### Setup

```swift
// In FlowStateApp.swift
@StateObject private var workoutStateManager = WorkoutStateManager()

var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(workoutStateManager)
    }
}
```

**Rules:**
- Create in app root
- Inject via `.environmentObject()`
- Use `@EnvironmentObject` in child views (never `@StateObject` or `@ObservedObject`)

### Usage

```swift
struct ChildView: View {
    @EnvironmentObject private var workoutState: WorkoutStateManager
    
    var body: some View {
        // Use workoutState
    }
}
```

**Rules:**
- Use `@EnvironmentObject` (not `@ObservedObject`)
- Make private when not passed to children
- No need to pass via initializer

---

## Timer Patterns

### Timer in ViewModel

```swift
nonisolated(unsafe) private var timer: Timer?

private func startTimer() {
    stopTimer()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            self?.updateState()
        }
    }
}

private func stopTimer() {
    timer?.invalidate()
    timer = nil
}

nonisolated deinit {
    timer?.invalidate()
    timer = nil
}
```

**Rules:**
- Use `nonisolated(unsafe)` for timer property
- Always stop timer before starting new one
- Use `[weak self]` in timer closure
- Update UI on `@MainActor`
- Clean up in `deinit` (must be nonisolated)

---

## Adding New Features

### 1. Define Models (if needed)

```swift
// In Models/
@Model
final class NewModel {
    var id: UUID
    // Properties
}
```

### 2. Create ViewModel

```swift
// In ViewModels/
final class NewFeatureViewModel: ObservableObject {
    @Published var data: [Model] = []
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    // Methods
}
```

### 3. Create Views

```swift
// In Views/
struct NewFeatureView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NewFeatureViewModel()
    
    var body: some View {
        // UI
    }
}
```

### 4. Integrate Navigation

- Add to TabView (if needed)
- Add navigation links from parent views
- Register models in `FlowStateApp.swift` schema

---

## Code Style

### Formatting

- 4 spaces for indentation (not tabs)
- No trailing whitespace
- Line breaks before closing braces for multiline blocks
- Keep lines under 120 characters when possible

### Comments

- Use `//` for inline comments
- Use `/**/` for block comments (rarely needed)
- Header comments in files (auto-generated by Xcode template)
- Add comments for complex logic only

### Imports

```swift
import Foundation
import SwiftUI
import SwiftData
import Combine
```

**Order:**
1. Foundation
2. SwiftUI
3. SwiftData
4. Combine (if needed)

---

## Testing Patterns

(Not yet implemented, but guidelines for future)

- Unit tests for ViewModels
- Test data setup in `setUp()`
- Use in-memory ModelContainer for tests
- Mock ViewModels for UI tests

---

## Common Pitfalls to Avoid

### ❌ Don't

- Access `setsData` directly (use `getSets()` / `setSets()`)
- Use `@StateObject` for `@EnvironmentObject`
- Hold strong reference to `ModelContext` in ViewModels
- Forget to call `modelContext.save()` after mutations
- Create multiple `WorkoutStateManager` instances
- Access SwiftData outside of `@MainActor` (for UI updates)

### ✅ Do

- Use helper methods for SetRecord operations
- Use `@EnvironmentObject` for app-wide state
- Guard against nil `modelContext`
- Save after all mutations
- Use `@StateObject` for view-owned ViewModels
- Use `@ObservedObject` for passed ViewModels
- Update UI on `@MainActor`

---

## Summary Checklist

When adding a new feature:

- [ ] Follow folder structure (Models/ViewModels/Views)
- [ ] Use consistent naming conventions
- [ ] Initialize ViewModel with `setModelContext()`
- [ ] Use `@Published` for reactive properties
- [ ] Handle errors (print for now)
- [ ] Use helper methods for SetRecord
- [ ] Register new models in `FlowStateApp.swift`
- [ ] Add navigation/entry points
- [ ] Test basic functionality
