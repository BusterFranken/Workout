# Workouts (iOS)

A SwiftUI + SwiftData iOS app for weekly workout checklisting, library management, and progression tracking.

## Features implemented

- `Workout` tab
  - View modes: `Muscle Groups`, `Weekdays`, and `Custom` (Workout A-E).
  - Swipe right to mark done, swipe left for edit/delete.
  - Editable exercises with separate `sets`, `reps/seconds`, `weight`, secondary muscle groups, and notes.
  - Check workflow with `Done this week` section (tap opens detail/progression).
  - Top goal cards (`#/target`), custom goal cards (up to 3), long-press wiggle + drag reorder.
  - Editable workout name + menu actions (new week, save, delete, change view).
  - Exercise detail overlay with progression charts.

- `Tracking` tab
  - Weekly sets chart.
  - All-time workout-days heatmap with month markers.
  - Sets per muscle group with expandable exercise progress (`done sets so far`).
  - Multi-line trend graph for sets per main muscle group.
  - Body Metrics cards (Scale Weight + Visual Body Fat) with `Add Weigh-In`.
  - Per-exercise progression charts (`weight`, `kg*reps`).
  - Classic PR list with tap-to-open PR history + manual add.

- `Library` tab
  - Bottom search bar over template names, exercise names, muscle groups, and synonyms.
  - Add full template to weekly workout (`add unique` or `replace current`) or add single exercise.
  - Template and exercise detail overlays.
  - Upload workout from pasted text or CSV/TXT file (line-based parser).

- `More` tab
  - Units (`kg/lb`), theme preference (`system/light/dark`), and contact page.

- Data model
  - Active week and saved library templates are separate entities.
  - Completion logging is immutable snapshot-based for reliable tracking over edits.

## Seed data

The default library includes your imported workout catalog from `Workouts DB (1).xlsx`.

## Build options

### Option A: XcodeGen project

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. From this folder run:

```bash
xcodegen generate
```

3. Open `WorkoutTracker.xcodeproj` in Xcode and run on iOS simulator/device.

### Option B: Swift Package

This repo also includes a `Package.swift` for source indexing and package workflows.
