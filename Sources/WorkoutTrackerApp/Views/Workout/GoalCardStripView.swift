import SwiftUI

struct GoalCardStripView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isEditing: Bool
    @Binding var showingTargetEditor: Bool

    @State private var showingAddGoal = false
    @State private var editingGoalCard: GoalCardEntity?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(repository.activeGoalSnapshots) { snapshot in
                        GoalCardView(
                            snapshot: snapshot,
                            isEditing: isEditing,
                            onDelete: { repository.archiveGoal(snapshot.card) },
                            onEdit: {
                                if snapshot.card.isSystem {
                                    showingTargetEditor = true
                                } else {
                                    editingGoalCard = snapshot.card
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
        .sheet(item: $editingGoalCard) { card in
            EditGoalSheet(card: card, editingCard: $editingGoalCard)
                .environmentObject(repository)
        }
    }
}

private struct GoalCardView: View {
    let snapshot: GoalSnapshot
    let isEditing: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snapshot.title)
                    .font(.headline)
                Spacer(minLength: 6)
                if isEditing && !snapshot.card.isSystem {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.warning)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
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

private enum GoalCategory: String, CaseIterable {
    case sets, exercises, workoutDays, volume, reps

    var displayName: String {
        switch self {
        case .sets: return "Sets"
        case .exercises: return "Exercises"
        case .workoutDays: return "Workout Days"
        case .volume: return "Volume Load"
        case .reps: return "Reps"
        }
    }

    var supportsMuscleGroup: Bool { self != .workoutDays }

    var defaultTarget: Int {
        switch self {
        case .sets: return 20
        case .exercises: return 10
        case .workoutDays: return 4
        case .volume: return 10000
        case .reps: return 200
        }
    }

    func metricType(forMuscleGroup: Bool) -> GoalMetricType {
        switch self {
        case .sets: return forMuscleGroup ? .muscleGroupSets : .totalSets
        case .exercises: return forMuscleGroup ? .muscleGroupExercises : .exercisesDone
        case .workoutDays: return .workoutDays
        case .volume: return forMuscleGroup ? .muscleGroupVolume : .totalVolume
        case .reps: return forMuscleGroup ? .muscleGroupReps : .totalReps
        }
    }

    var suffix: String {
        switch self {
        case .sets: return "Sets"
        case .exercises: return "Exercises"
        case .workoutDays: return "Workout Days"
        case .volume: return "Volume"
        case .reps: return "Reps"
        }
    }
}

private struct AddGoalSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isPresented: Bool

    @State private var category: GoalCategory = .exercises
    @State private var target: Int = 10
    @State private var selectedMuscleGroupID: UUID?

    private var needsMuscleGroup: Bool {
        category.supportsMuscleGroup && selectedMuscleGroupID != nil
    }

    private var targetRange: ClosedRange<Int> {
        switch category {
        case .volume, .reps: return 1...99999
        default: return 1...300
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: category) { _, _ in
                        selectedMuscleGroupID = nil
                        target = category.defaultTarget
                    }

                    if category.supportsMuscleGroup {
                        Picker("Scope", selection: $selectedMuscleGroupID) {
                            Text("All muscle groups").tag(Optional<UUID>.none)
                            ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                    }
                }

                Section("Target") {
                    if category == .volume || category == .reps {
                        HStack {
                            Text("Target")
                            Spacer()
                            TextField("Target", value: $target, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    } else {
                        Stepper(value: $target, in: targetRange) {
                            Text("\(target)")
                        }
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
                        let hasMuscleGroup = selectedMuscleGroupID != nil
                        let metric = category.metricType(forMuscleGroup: hasMuscleGroup)

                        let title: String
                        if hasMuscleGroup,
                           let id = selectedMuscleGroupID,
                           let group = repository.muscleGroups.first(where: { $0.id == id }) {
                            title = "\(group.name) \(category.suffix)"
                        } else {
                            title = category.displayName
                        }

                        repository.addCustomGoal(
                            metric: metric,
                            target: target,
                            title: title,
                            muscleGroupID: selectedMuscleGroupID
                        )
                        isPresented = false
                    }
                }
            }
        }
    }
}

private struct EditGoalSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let card: GoalCardEntity
    @Binding var editingCard: GoalCardEntity?

    @State private var target: Int
    @State private var showingDeleteConfirmation = false

    init(card: GoalCardEntity, editingCard: Binding<GoalCardEntity?>) {
        self.card = card
        self._editingCard = editingCard
        self._target = State(initialValue: card.targetValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    Stepper(value: $target, in: 1...300) {
                        Text("\(target)")
                    }
                }

                if !card.isSystem {
                    Section {
                        Button("Delete Goal", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingCard = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.updateGoalTarget(card, target: target)
                        editingCard = nil
                    }
                }
            }
            .confirmationDialog(
                "Delete this goal?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Goal", role: .destructive) {
                    repository.archiveGoal(card)
                    editingCard = nil
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This goal will be removed from your dashboard.")
            }
        }
    }
}
