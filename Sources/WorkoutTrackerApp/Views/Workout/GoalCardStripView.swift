import SwiftUI

struct GoalCardStripView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isEditing: Bool
    @Binding var showingTargetEditor: Bool

    @State private var showingAddGoal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(repository.activeGoalSnapshots) { snapshot in
                        GoalCardView(
                            snapshot: snapshot,
                            isEditing: isEditing,
                            onDelete: { repository.archiveGoal(snapshot.card) },
                            onEditDefault: {
                                if snapshot.card.isSystem {
                                    showingTargetEditor = true
                                }
                            }
                        )
                        .draggable(snapshot.id.uuidString)
                        .dropDestination(for: String.self) { items, _ in
                            guard isEditing,
                                  let moved = items.first,
                                  let sourceID = UUID(uuidString: moved),
                                  sourceID != snapshot.id,
                                  let destination = repository.activeGoalSnapshots.firstIndex(where: { $0.id == snapshot.id })
                            else {
                                return false
                            }
                            repository.reorderGoals(from: sourceID, to: destination)
                            return true
                        }
                    }

                    if repository.activeGoalSnapshots.count < 3 {
                        Button {
                            showingAddGoal = true
                            Haptics.soft()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.primaryText)
                                .padding(8)
                                .background(Circle().fill(Theme.mutedSurface))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isEditing {
                Text("Drag cards to reorder")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(isPresented: $showingAddGoal)
                .environmentObject(repository)
        }
    }
}

private struct GoalCardView: View {
    let snapshot: GoalSnapshot
    let isEditing: Bool
    let onDelete: () -> Void
    let onEditDefault: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snapshot.title)
                    .font(.headline)
                Spacer(minLength: 6)
                if snapshot.card.isSystem {
                    Button(action: onEditDefault) {
                        Image(systemName: "pencil")
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                } else if isEditing {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.warning)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("\(snapshot.currentValue)/\(snapshot.targetValue)")
                .font(.monoMetric)

            Text(snapshot.currentValue >= snapshot.targetValue ? "Goal hit" : "\(snapshot.targetValue - snapshot.currentValue) left")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(14)
        .frame(width: 165, alignment: .leading)
        .appCard(cornerRadius: 18)
        .wiggle(isEditing)
    }
}

private struct AddGoalSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isPresented: Bool

    @State private var metric: GoalMetricType = .exercisesDone
    @State private var target: Int = 10
    @State private var selectedMuscleGroupID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Type", selection: $metric) {
                        ForEach([GoalMetricType.totalSets, .exercisesDone, .muscleGroupSets, .workoutDays], id: \.self) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.menu)

                    if metric == .muscleGroupSets {
                        Picker("Muscle", selection: $selectedMuscleGroupID) {
                            Text("Pick a muscle").tag(Optional<UUID>.none)
                            ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                    }
                }

                Section("Target") {
                    Stepper(value: $target, in: 1...300) {
                        Text("\(target)")
                    }
                }
            }
            .navigationTitle("Add Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let title: String
                        switch metric {
                        case .totalSets:
                            title = "Sets"
                        case .exercisesDone:
                            title = "Exercises"
                        case .muscleGroupSets:
                            if let id = selectedMuscleGroupID,
                               let group = repository.muscleGroups.first(where: { $0.id == id }) {
                                title = group.name
                            } else {
                                title = "Muscle Sets"
                            }
                        case .workoutDays:
                            title = "Workout Days"
                        }

                        repository.addCustomGoal(
                            metric: metric,
                            target: target,
                            title: title,
                            muscleGroupID: selectedMuscleGroupID
                        )
                        isPresented = false
                    }
                    .disabled(metric == .muscleGroupSets && selectedMuscleGroupID == nil)
                }
            }
        }
    }
}
