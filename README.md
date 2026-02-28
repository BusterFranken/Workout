# WorkoutTracker (iOS)

A SwiftUI + SwiftData iOS app for weekly workout checklisting, library management, and progression tracking.

## Features implemented

- `Workout` tab
  - Muscle-group headers with done counters.
  - Editable exercises with separate `sets`, `reps/seconds`, `weight kg`, and `weight count`.
  - Check/uncheck workflow with `Done this week` section.
  - Top goal cards (`#/target`), custom goal cards (up to 3), long-press wiggle + drag reorder.
  - Menu actions: add muscle group, start new week, save workout to library, delete weekly workout.
  - Exercise detail overlay with progression charts.

- `Tracking` tab
  - Weekly sets chart.
  - Last-30-days workout heatmap.
  - Sets per muscle group with expandable exercise lists.
  - Per-exercise progression charts (`weight`, `kg*reps`).
  - Classic PR snapshots (deadlift, pull ups, weighted pull ups, bench press, squat).

- `Library` tab
  - Searchable workout templates and exercise catalog (name + muscle group).
  - Add full template or single exercise to active week.
  - Upload workout from pasted text or CSV/TXT file (line-based parser).

- Data model
  - Active week and saved library templates are separate entities.
  - Completion logging is immutable snapshot-based for reliable tracking over edits.

## Seed data

The default library includes your imported workout catalog from `Workouts DB.xlsx`.

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
