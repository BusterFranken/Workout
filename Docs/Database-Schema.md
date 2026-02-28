# Database Schema (SwiftData / SQLite)

## Core entities

- `AppSettingsEntity`
  - Singleton app-level state (`activeWeekStartDate`, `weeklySetTarget`, `seedVersion`).

- `MuscleGroupEntity`
  - Editable headers shown on the workout page.
  - Keeps stable `id` so renaming does not break historical links.

- `ExerciseEntity`
  - Canonical exercise catalog entry in Library.
  - Uses immutable `id` as canonical identifier even when name changes.

- `WorkoutTemplateEntity`
  - Saved weekly workouts in Library.
  - Snapshot metadata (`name`, timestamps).

- `WorkoutTemplateExerciseEntity`
  - Snapshot rows for each template exercise (muscle group + sets/reps/seconds/weight/count).

- `WeeklyExerciseEntity`
  - Active-week rows shown in Workout tab.
  - Check state, ordering, and editable fields live here.
  - Soft-delete via `removedAt`.

- `CompletionLogEntity`
  - Immutable snapshots created on check-off.
  - Stores sets/reps/seconds/weight/count/date so tracking remains stable even if exercise is edited later.

- `GoalCardEntity`
  - Top-of-screen widgets for goals.
  - Includes system default goal + user custom goals (max 3 visible).

## Key behavior mapping

- **Weekly reset**: `startNewWeek()` clones active rows to a new `weekStartDate` with unchecked state.
- **Check off exercise**: updates `WeeklyExerciseEntity.completedAt` and inserts one `CompletionLogEntity` snapshot.
- **Uncheck exercise**: clears `completedAt` and removes this week's snapshot log for that row.
- **Delete from weekly workout**: soft-delete (`removedAt`) only; historical logs remain.
- **Save weekly workout to library**: creates `WorkoutTemplateEntity` + `WorkoutTemplateExerciseEntity` snapshots and upserts exercises into `ExerciseEntity`.

## Metric formulas

- **Sets done this week**: `sum(sets)` over checked `WeeklyExerciseEntity` rows.
- **Muscle volume this week**: `sum(setsSnapshot)` over `CompletionLogEntity` filtered by muscle group + week.
- **Load progression (`kg * reps`)**: `weightKgSnapshot * weightCountSnapshot * repsSnapshot`.
