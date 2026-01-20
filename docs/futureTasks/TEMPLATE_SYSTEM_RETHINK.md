# Template System Rethink (Selection, Additions, Management, UX)

## Context / Why this exists
Templates are one of FlowState’s strongest features: they enable fast workout starts and reduce repetitive setup. However, the *overall* experience (template selection, starting, editing, adding exercises, duplication, and management) currently mixes multiple user intents across multiple surfaces, which can create ambiguity, friction, and future feature constraints.

This document captures:
- **How Templates work today** in the app (data model, view models, screens, and user flows).
- **What’s good / what’s brittle** (pros/cons, technical and UX).
- **What users likely like / dislike** (expectations from workout apps and the current FlowState implementation).
- **A comprehensive future direction** for rethinking Templates end-to-end (multiple options + recommended path).
- **A phased plan** to evolve the system without breaking existing data.

> Status: **Future plan** (no implementation yet).

---

## Current system: “Templates” in FlowState today

### What a Template is (data model)
Templates are persisted using SwiftData models:

- **`WorkoutTemplate`** (`FlowState/Models/WorkoutTemplate.swift`)
  - **`id: UUID`**
  - **`name: String`**
  - **`createdAt: Date`**
  - **`lastUsedAt: Date?`**
  - **`exercises: [TemplateExercise]?`** (SwiftData relationship, **cascade delete**)

- **`TemplateExercise`** (`FlowState/Models/TemplateExercise.swift`)
  - **`id: UUID`**
  - **`order: Int`** (0-based ordering within template)
  - **`defaultSets: Int`**
  - **`defaultReps: Int`**
  - **`defaultWeight: Double?`**
  - Relationship **to `Exercise`** (library exercise)
  - Relationship **back to `WorkoutTemplate`**

Key implication:
- A template stores **structure** (exercise list + default set “shape”) *and* **optional load** (default weight). When used, it becomes the starter blueprint for an active workout.

---

### How starting a workout from a template works (copy semantics)
Starting a workout from a template happens in the active workout layer:

- **`ActiveWorkoutViewModel.startWorkoutFromTemplate(_ template: WorkoutTemplate, discardExisting: Bool = false)`**
  - Creates a new **`Workout`** with:
    - `name = template.name`
    - `startedAt = Date()`
    - `completedAt = nil`
  - Copies each `TemplateExercise` into a **`WorkoutEntry`**:
    - Uses `TemplateExercise.order` to set `WorkoutEntry.order`
  - Pre-populates **`SetRecord`s** for each entry:
    - Creates `defaultSets` count
    - Each set uses `defaultReps` and `defaultWeight`
  - Saves to SwiftData
  - Updates template usage:
    - `template.lastUsedAt = Date()`

Important behavior:
- This is a **copy-at-start** model: once started, workout entries/sets are independent of the template.

---

### Where Templates appear in the UI

#### Home (primary discovery + start)
`FlowState/Views/HomeView.swift`

Home has a Templates section titled **“Start From Template”**:
- Horizontal list of up to ~5 templates (currently `templates.prefix(5)`).
- Each card:
  - Shows template name
  - Preview of first 3 exercises + “+N more”
  - “Last used …” indicator from `lastUsedAt` (relative formatting)
  - Exercise count
  - A “play” icon that implies start
- Tap behavior:
  - Sets `selectedTemplate` and shows a confirm alert (“Start workout from …?”)
  - If an active workout exists, shows a **discard-and-start** alert
- Long-press context menu on the card:
  - Edit Template (opens edit flow)
  - Duplicate
  - Delete

Home therefore supports *both*:
- **Starting** from templates (primary intent)
- **Managing** templates (secondary intent, but exposed inline)

#### Template List (library screen)
`FlowState/Views/TemplateListView.swift`

This is the “See All” library:
- Lists templates (sorted by lastUsedAt then createdAt via `TemplateViewModel.fetchAllTemplates()`)
- NavigationLink to detail/edit view
- Swipe-to-delete in list
- Plus button to create new template

#### Template Detail (edit template)
`FlowState/Views/TemplateDetailView.swift`

This view is labeled “Edit Template” and supports:
- Edit name (TextField)
- View exercises (ordered), move (EditButton / drag), delete
- “Add Exercise” (sheet)
- Tap an exercise row to edit its defaults (sets/reps/weight)
- Save / Cancel (dismiss)

Notable implementation detail:
- `TemplateDetailView` keeps local `@State` copies:
  - `templateName`
  - `templateExercises` (local array)
- Deletions can occur both in the local array and via `modelContext.delete(...)`
- Saving assigns `template.exercises = templateExercises` then `modelContext.save()`

#### Create Template (create new)
`FlowState/Views/CreateTemplateView.swift`

This view supports:
- Enter template name
- Add exercises (sheet)
- Optional editing per exercise defaults (sheet)
- Create button inserts template + inserts exercises, links relationships, saves

#### Add exercises to template
There are two sheet implementations:
- `AddExerciseToTemplateSheet` (for existing template)
- `AddExerciseToNewTemplateSheet` (for new template)

Both:
- Show the exercise library grouped by category, with a multi-select UI.
- “Done” creates new `TemplateExercise`s with default values (3×10, no weight) and appends them.

Notable:
- For existing templates, `AddExerciseToTemplateSheet` **also inserts the new TemplateExercise into modelContext and saves immediately**, even though the template’s `exercises` list is formally “committed” on the template edit Save.

#### Edit a template exercise defaults
`EditTemplateExerciseSheet`
- Lets user change sets, reps, and optional weight via custom numpad.
- If the `TemplateExercise` is already persisted, it saves to SwiftData immediately.
- If the `TemplateExercise` is “temporary” (new template flow), it only mutates the object and relies on creation-time save.

---

## Current experience: major user intents and where they live

### Intent A: “Start a workout quickly”
Current surfaces:
- Home template cards (tap + confirm)
- Potentially TemplateList → TemplateDetail (but that screen is edit-focused)

### Intent B: “Manage my routines”
Current surfaces:
- Home template card context menu (edit/duplicate/delete)
- TemplateList list swipe delete + create
- TemplateDetail (edit everything)

### Intent C: “Prepare this template for today (but don’t change it forever)”
Current support:
- **Not explicit.**
- Users must either:
  - Start the workout and then modify the active workout (add/remove/reorder exercises, add/remove sets), or
  - Edit the template (which changes future starts), or
  - Duplicate the template (increases template count / management burden).

This missing intent is often the root of “templates feel stressful / too permanent.”

---

## Pros of the current template system

### UX wins
- **Fast start**: one tap from Home + a confirmation.
- **High-signal cards**: exercise preview + last used + count is scannable (see `docs/pastTasks/TEMPLATE_CARDS_AND_LOADING_STATES.md`).
- **Works offline & instantly**: local SwiftData operations.
- **Simple mental model (initially)**: “Pick routine → Start workout.”

### Technical wins
- **Clear relationships**: template → templateExercises, cascade delete keeps DB tidy.
- **Copy semantics are safe**: once a workout starts, changes don’t affect template.
- **Ordering is explicit** (`order: Int`).
- **Low schema complexity**: only 2 template models.

---

## Cons / risk areas today (UX + technical)

### 1) Mixed intents on Home (Start vs Manage)
Home cards are primarily “start” affordances, but also contain management actions (edit/duplicate/delete).
Potential downsides:
- Users can accidentally treat templates as “things you tweak today” and end up editing the canonical routine.
- Management actions are present in a place where users may not expect destructive changes.

### 2) “Editing permanence” ambiguity (Template vs Workout)
Today, users often want:
- “Start this routine but remove one exercise today”
- “Start this routine but change rep targets today”
- “Start this routine but don’t carry weight defaults forever”

Without a “prep” layer, users either:
- modify the template (permanent), or
- modify the active workout (after starting), or
- duplicate templates (library bloat).

### 3) Template weight defaults can be conceptually wrong
Weights are highly contextual (fatigue, equipment, microloading, day-to-day readiness). Persisting a single “default weight” per exercise inside a template can create:
- **Stale defaults** that are wrong after a few weeks.
- **Cognitive friction** (“Do I edit the template weight every time?”).
- **Template explosion** (users duplicate templates just to preserve different weight scenarios).

This can still be useful for certain use cases (e.g., beginner linear progression), but the default UX should not require templates to be “kept up to date” like a spreadsheet.

### 4) Data mutation timing is inconsistent (immediate saves vs staged saves)
Examples:
- `AddExerciseToTemplateSheet` inserts `TemplateExercise`s into SwiftData and saves immediately.
- `TemplateDetailView` is largely staged in local `@State` and only commits when Save is tapped.
- `EditTemplateExerciseSheet` sometimes saves immediately, sometimes not (depending on `isTemporary`).

Potential downsides:
- Harder to reason about “Cancel” vs “Save”.
- Easier to create partially-applied changes (especially if a user dismisses sheets in unexpected orders).
- Makes future features (undo, draft editing, versioning) harder.

### 5) Ordering + identity concerns
Ordering is tracked by a mutable `order: Int` on `TemplateExercise`.
- Works, but requires careful reindexing on move/delete.
- “Order as source of truth” can be fragile if multiple arrays are modified in different views and then recombined.

### 6) Library growth and curation burden
Because the system does not support “today-only tweaks” as a first-class concept, users may:
- Duplicate templates frequently (“Push Day”, “Push Day (copy)”, “Push Day (copy) (copy)”)
- Lose confidence in which template is “the canonical” one
- Avoid editing templates altogether, because it feels risky

---

## What users likely like / dislike (based on workout app expectations)

### Users likely like
- **Speed**: start a workout in 1–2 taps.
- **Predictability**: templates always start the same way (structure).
- **Preview**: seeing what’s inside before starting.
- **Recency relevance**: “last used” and “recent templates” bubble up.
- **Low friction iteration**: easy to adjust set counts and reps.

### Users likely dislike
- **Accidental permanence**: “I changed the template when I meant today’s workout.”
- **Management clutter**: too many templates, hard to find the one they want.
- **Weight maintenance**: having to edit template weights frequently.
- **Ambiguous flows**: not knowing whether they are editing a template, editing today’s workout, or editing defaults.
- **Over-confirmation**: repeated alerts for start/discard can feel heavy (necessary for safety, but should be well-scoped).

### “What users mean” when they say “Template”
In fitness apps, “Template” often conflates two different concepts:
- **Routine (canonical plan)**: a curated program-like template that changes rarely.
- **Preset (quick start)**: a convenience shortcut that can change often.

FlowState currently treats templates as both, without clear UX separation.

---

## Design goals for a rethought template system

### Primary goals
- **Separate starting from managing** so the default experience is safe and simple.
- **Support “today-only tweaks” explicitly** (prep / quick adjust) so users don’t duplicate templates for small changes.
- **Reduce cognitive load**: fewer concepts on any single screen; predictable actions.
- **Preserve speed**: starting from template should remain near-instant.

### Secondary goals
- **Scalable library**: search, pinning, sorting, folders/tags (future).
- **Better defaults**: “suggested weight” from history rather than static template weights (optional).
- **Clean state + persistence**: consistent save semantics (draft vs committed).

---

## Proposed “new thought process”: split Template into two jobs

### Job A: Start a workout
User intent: “Give me a good structure for today quickly.”

Properties:
- Fast, safe, low decision-making.
- Prefer read-only surfaces.
- Avoid destructive actions.

### Job B: Manage routines
User intent: “Let me curate and maintain my saved routines.”

Properties:
- More power is fine, but should be entered intentionally.
- Supports organization and bulk actions over time.

This split is the foundation. Everything below builds from it.

---

## UX redesign options (with trade-offs)

### Option 1 (Recommended): Template Library + Read-only Detail + “Start & Tweak”
**Summary**
- Home: show *Pinned* + *Recent* templates; cards are **start-only**.
- Template Library: the single hub for management.
- Template Detail: read-only by default, with explicit entry points:
  - **Start Workout**
  - **Start & Tweak (Today Only)**
  - **Edit Template** (explicit edit mode)

**Why it’s strong**
- Eliminates accidental permanence.
- Adds the missing “today-only prep” intent without complicating the active workout view.
- Keeps Home lightweight and safe.

**Costs / complexity**
- New “prep/tweak” screen (or sheet) needs to exist.
- Need to define how tweak state maps into `WorkoutEntry` creation.

### Option 2: Keep current surfaces, add “Edit Mode” gating
**Summary**
- Home remains as-is, but management actions require an explicit “Manage” toggle or a dedicated “Manage templates” entry.
- TemplateDetail becomes read-only until user taps “Edit”.

**Why it’s good**
- Minimal navigation changes; less rework.

**Why it may not be enough**
- Still doesn’t solve “today-only tweaks” well.
- Home is still a mixed-intent surface.

### Option 3: Templates become ephemeral presets; “Routines” become a new model
**Summary**
- Introduce a new top-level concept (“Routine”) distinct from “Template/Preset.”
- Presets are lightweight quick-starts; routines are curated and organized.

**Why it’s good**
- Extremely clear mental model.

**Why it’s risky now**
- Adds complexity early (new model, migration, new UI language).
- Might be overkill before you have user volume.

---

## Recommended direction (concrete)

### 1) Home becomes “Start-only”
Home’s Template cards should do:
- Tap → Start (or Start sheet)
- Optional: long-press could show **non-destructive** actions (e.g., Pin/Unpin) but avoid delete/edit here.

All destructive + editing actions should live in the Template Library.

### 2) Template Detail is read-only by default
Instead of landing users immediately in a form that edits persistent state, Template Detail should initially answer:
- “What is this template?”
- “Do you want to start from it?”

**Proposed default actions**
- **Primary**: Start Workout
- **Secondary**: Start & Tweak (Today Only)
- **Tertiary**: Edit Template (explicitly enters edit mode)

**Proposed info shown**
- Template name
- Exercise list (ordered)
- Per-exercise defaults (sets × reps, optional weight if still supported)
- “Last used” and “Created”

**Edit mode entry**
- Edit mode should be intentionally entered (button → builder)
- Ideally uses a staged draft with Save/Cancel semantics (no immediate mutation until Save)

---

### 3) Introduce “Start & Tweak (Today Only)” as a first-class flow
This is the missing user intent today.

**What it is**
A lightweight “prep” step between selecting a template and starting the workout, where changes apply only to the workout that will be created.

**What users can tweak**
- Remove exercises for today
- Reorder exercises for today
- Adjust default sets/reps (and optional weight) for today
- Optionally “clear weight defaults” for today
- Optional: add one-off exercises for today (either here or after starting)

**What users can do after tweaking**
- **Start Workout** (creates `Workout` and `WorkoutEntry`s using the tweaked draft)
- **Save these changes as…**
  - Save as a new template (creates variant)
  - Update existing template (explicit, destructive, confirmed)

**Why this matters**
- Reduces duplicate templates
- Reduces fear of editing
- Makes templates feel like *helpful starting points* rather than *fragile canonical documents*

---

### 4) Template Library becomes the single management hub
Today management is split across Home (context menus) and TemplateList/Detail. Consolidate management into a dedicated “Library” surface.

**Library requirements**
- Search by template name
- Sort options (at minimum):
  - Pinned first, then last used
  - Alphabetical
  - Recently created
- Basic organization:
  - Pin / Unpin (for Home surfacing)
  - Archive / Unarchive (hide clutter without deleting)
- Bulk-safe actions:
  - Duplicate
  - Rename
  - Delete (destructive confirmation)

**Home behavior**
- Home should show:
  - Pinned templates (primary)
  - Recent templates (secondary)
  - “See All” → Library

---

### 5) Re-evaluate what defaults belong in a template
Templates can store different “kinds” of defaults:
- **Structure defaults** (almost always good):
  - exercise list + order
  - default set count
  - rep target (or rep range)
- **Load defaults** (situational):
  - defaultWeight

**Recommendation**
- Keep `defaultWeight` support but change the default UX so weight is:
  - optional, and
  - not something users feel required to maintain.

**Best-in-class alternative**
Use *suggested weight* at workout start based on history (e.g., last performed, last successful, or some progression rule) rather than template-stored weight.

If implementing suggestions:
- Templates store *rep intent* and *set count*
- Workouts pull suggested weight from:
  - last workout entry for that exercise, or
  - PR + heuristic, or
  - “last 7 days average”, etc.

---

## Data model evolution ideas (non-breaking first)

### “Minimum viable” additions
Add fields to `WorkoutTemplate`:
- `isPinned: Bool` (default false)
- `archivedAt: Date?` (nil = active)
- `updatedAt: Date` (for “recently edited” sorting)

Optional additions to `TemplateExercise`:
- `repMode` (future): fixed reps vs rep range (e.g., 6–8)
- `note` (future): “use incline bench”, “tempo”, etc.

### Consider normalizing template ordering
Current approach uses `TemplateExercise.order: Int`.
This is fine, but ensure future refactors keep a single source of truth:
- Always reindex on move/delete
- Avoid multiple independent arrays becoming authoritative in different views

### Keep copy-at-start semantics
This is a major strength. Any redesign should preserve:
- Template edits do not retroactively mutate past workouts
- Workouts started from templates are independent objects

---

## Technical implementation considerations (current codebase)

### Current template touchpoints
- Models:
  - `FlowState/Models/WorkoutTemplate.swift`
  - `FlowState/Models/TemplateExercise.swift`
- Template view model:
  - `FlowState/ViewModels/TemplateViewModel.swift`
- Start-from-template copy logic:
  - `FlowState/ViewModels/ActiveWorkoutViewModel.swift`
- UI:
  - `FlowState/Views/HomeView.swift` (cards, start alert, context menu)
  - `FlowState/Views/TemplateListView.swift`
  - `FlowState/Views/TemplateDetailView.swift` (edit)
  - `FlowState/Views/CreateTemplateView.swift` (create)
  - `FlowState/Views/AddExerciseToTemplateSheet.swift`
  - `FlowState/Views/EditTemplateExerciseSheet.swift`

### Consistency goal: one save strategy per flow
Pick one of:
- **Draft editing**: all changes staged in memory until Save, then persisted
- **Live editing**: changes persist immediately, and Cancel does not revert (usually worse UX for “edit template”)

For templates, draft editing tends to be the better user experience.

### Reduce “partial mutation” surfaces
If Template editing is draft-based:
- Adding exercises in the sheet should mutate only the draft list, not SwiftData immediately.
- The final Save commits inserts/deletes in one transaction.

### Active workout conflict handling
This already exists on Home:
- starting a new workout prompts discard if an active workout exists

Future improvement:
- Use consistent copy + discard logic regardless of entry point (Home, Library, Template Detail).

---

## Edge cases to design for

### 1) Starting while an active workout exists
Required behavior:
- Always safe
- Always consistent
- Clear choices:
  - Cancel
  - Discard & Start (destructive)

### 2) Deleted or missing exercises
If an `Exercise` referenced by a `TemplateExercise` is removed/invalid:
- Decide whether:
  - templates should show “Unknown Exercise” rows (current behavior exists in some places), or
  - templates should automatically prune invalid exercises, or
  - exercises should not be deletable if referenced (currently not enforced).

### 3) Rapid repeated edits / sheet dismissal ordering
If the app uses draft editing:
- Dismissing add/edit sheets should not partially persist changes.

### 4) Reordering and order collisions
Ensure reordering logic always results in:
- contiguous ordering from 0...n-1
- stable UI updates

### 5) Template duplication explosion
If a user duplicates often:
- Provide tools to reduce clutter:
  - archive
  - pin canonical
  - “save as new” from tweak flow with better naming prompts

### 6) Units + weight defaults
Currently weights are stored in lbs internally (app-wide pattern).
Template weights should follow the same rule (confirm current behavior).
If adding “suggested weight,” ensure conversion is consistent.

---

## Success criteria (what “better templates” looks like)

### UX outcomes
- Starting from template remains fast (no more than +1 step for “Start & Tweak” path).
- Users can confidently adjust a template “for today” without fear.
- Library remains navigable as template count grows.
- Users are less likely to duplicate templates just to make small variants.

### Product outcomes (observable)
- Higher template usage frequency (more “start from template”)
- Lower template churn (fewer duplicated templates per week)
- Higher completion rates for workouts started from templates

---

## Phased implementation plan (recommended)

### Phase 0: Document + decide semantics (this doc)
- Confirm which concept templates should be:
  - routines (stable), presets (flexible), or both (with explicit UX separation)
- Decide how to handle weight:
  - keep static defaultWeight, or introduce suggested weights, or both

### Phase 1: Make Template Detail safe (read-only default + explicit Edit)
- Create a read-only Template Detail screen
- Move editing into an explicit “Edit Template” builder mode
- Keep existing data model; minimal migration

### Phase 2: Create a real Template Library
- Consolidate management actions into Library:
  - rename, duplicate, delete, archive
- Adjust Home cards to be start-only (remove destructive context menu)

### Phase 3: Add “Start & Tweak” (today-only prep)
- Add a prep screen/sheet that generates a workout draft from template
- Allow reorder/remove/adjust defaults (today only)
- Provide “Save as new template” and “Update template” actions

### Phase 4: Improve defaults (optional)
- Add suggested weight logic (from workout history)
- Add rep ranges and/or per-exercise notes
- Add pinning and archived templates if not done earlier

### Phase 5: Polish + future scalability
- Folder/tag organization (optional)
- Better search (include exercise names inside templates)
- Template analytics (optional)

---

## Open questions (to answer before building)
- Should templates be optimized for **routines** (stable) or **presets** (flexible)?
- Does FlowState want templates to store:
  - exact weights, or just structure + rep intent?
- When users “Save changes” from tweak flow:
  - default to updating the existing template, or default to “Save as new”?
- How should templates interact with cardio exercises (if/when templates support cardio sets)?
- Do we want template “variants” as a first-class notion (e.g., linked templates), or keep duplication simple?

---

## Out of scope (for this effort)
- Program planning (“8-week program builder”)
- Auto-progression algorithms (beyond simple suggested weights)
- Cloud sync / multi-device conflict resolution

