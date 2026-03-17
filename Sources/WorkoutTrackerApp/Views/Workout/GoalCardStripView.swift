import SwiftUI
import UniformTypeIdentifiers

struct GoalCardStripView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isEditing: Bool
    @Binding var showingTargetEditor: Bool

    @State private var showingAddGoal = false
    @State private var editingGoalCard: GoalCardEntity?
    @State private var activeDragGoalID: UUID?
    @State private var hoveredGoalInsertionIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    goalInsertionIndicator(at: 0)

                    ForEach(Array(repository.activeGoalSnapshots.enumerated()), id: \.element.id) { index, snapshot in
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
                        .onDrag {
                            activeDragGoalID = snapshot.id
                            Haptics.soft()
                            return NSItemProvider(object: snapshot.id.uuidString as NSString)
                        }
                        .onDrop(of: [UTType.plainText], delegate: GoalCardDropDelegate(
                            index: index,
                            cardWidth: 165,
                            activeDragGoalID: $activeDragGoalID,
                            hoveredGoalInsertionIndex: $hoveredGoalInsertionIndex,
                            onReorder: { sourceID, destination in
                                repository.reorderGoals(from: sourceID, to: destination)
                                Haptics.success()
                            }
                        ))

                        goalInsertionIndicator(at: index + 1)
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

    private func goalInsertionIndicator(at index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear.opacity(0.001))

            Rectangle()
                .fill(hoveredGoalInsertionIndex == index ? Theme.accent : .clear)
                .frame(width: hoveredGoalInsertionIndex == index ? 3 : 1)
        }
        .contentShape(Rectangle())
        .frame(width: 10)
    }
}

private struct GoalCardDropDelegate: DropDelegate {
    let index: Int
    let cardWidth: CGFloat
    @Binding var activeDragGoalID: UUID?
    @Binding var hoveredGoalInsertionIndex: Int?
    let onReorder: (UUID, Int) -> Void

    private func insertionIndex(for location: CGPoint) -> Int {
        location.x < (cardWidth * 0.5) ? index : index + 1
    }

    func validateDrop(info: DropInfo) -> Bool {
        activeDragGoalID != nil
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        hoveredGoalInsertionIndex = insertionIndex(for: info.location)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { return DropProposal(operation: .cancel) }
        hoveredGoalInsertionIndex = insertionIndex(for: info.location)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        hoveredGoalInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            hoveredGoalInsertionIndex = nil
            DispatchQueue.main.async {
                activeDragGoalID = nil
            }
        }
        guard let sourceID = activeDragGoalID else { return false }
        let destination = insertionIndex(for: info.location)
        onReorder(sourceID, destination)
        return true
    }
}

private struct GoalCardView: View {
    let snapshot: GoalSnapshot
    let isEditing: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void

    private var isGoalHit: Bool {
        snapshot.currentValue >= snapshot.targetValue && snapshot.targetValue > 0
    }

    private var progress: Double {
        guard snapshot.targetValue > 0 else { return 0 }
        return Double(snapshot.currentValue) / Double(snapshot.targetValue)
    }

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

            HStack(spacing: 4) {
                Text("\(snapshot.currentValue)/\(snapshot.targetValue)")
                    .font(.monoMetric)
                if isGoalHit {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.body)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.mutedSurface)
                    Capsule()
                        .fill(isGoalHit ? Color.green : Theme.accent)
                        .frame(width: max(0, geo.size.width * min(progress, 1.0)))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.4), value: snapshot.currentValue)
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

    init?(metricTypeRaw: String) {
        switch metricTypeRaw {
        case GoalMetricType.totalSets.rawValue, GoalMetricType.muscleGroupSets.rawValue: self = .sets
        case GoalMetricType.exercisesDone.rawValue, GoalMetricType.muscleGroupExercises.rawValue: self = .exercises
        case GoalMetricType.workoutDays.rawValue: self = .workoutDays
        case GoalMetricType.totalVolume.rawValue, GoalMetricType.muscleGroupVolume.rawValue: self = .volume
        case GoalMetricType.totalReps.rawValue, GoalMetricType.muscleGroupReps.rawValue: self = .reps
        default: return nil
        }
    }
}

private struct AddGoalSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isPresented: Bool

    @State private var category: GoalCategory = .exercises
    @State private var target: Int = 10
    @State private var selectedMuscleGroupID: UUID?
    @State private var selectedSubMuscle: String?

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
                        selectedSubMuscle = nil
                        target = category.defaultTarget
                    }

                    if category.supportsMuscleGroup {
                        Picker("Scope", selection: $selectedMuscleGroupID) {
                            Text("All muscle groups").tag(Optional<UUID>.none)
                            ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                        .onChange(of: selectedMuscleGroupID) { _, _ in
                            selectedSubMuscle = nil
                        }

                        if let groupID = selectedMuscleGroupID,
                           let groupName = repository.muscleGroups.first(where: { $0.id == groupID })?.name,
                           let subMuscles = SeedCatalog.subMuscles[groupName], !subMuscles.isEmpty {
                            Picker("Muscle", selection: $selectedSubMuscle) {
                                Text("Any / All").tag(Optional<String>.none)
                                ForEach(subMuscles, id: \.self) { sub in
                                    Text(sub).tag(Optional(sub))
                                }
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
                            let scopeName = selectedSubMuscle ?? group.name
                            title = "\(scopeName) \(category.suffix)"
                        } else {
                            title = category.displayName
                        }

                        repository.addCustomGoal(
                            metric: metric,
                            target: target,
                            title: title,
                            muscleGroupID: selectedMuscleGroupID,
                            subMuscleName: selectedSubMuscle
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

    @State private var category: GoalCategory
    @State private var target: Int
    @State private var selectedMuscleGroupID: UUID?
    @State private var selectedSubMuscle: String?
    @State private var showingDeleteConfirmation = false

    init(card: GoalCardEntity, editingCard: Binding<GoalCardEntity?>) {
        self.card = card
        self._editingCard = editingCard
        self._category = State(initialValue: GoalCategory(metricTypeRaw: card.metricTypeRaw) ?? .sets)
        self._target = State(initialValue: card.targetValue)
        self._selectedMuscleGroupID = State(initialValue: card.muscleGroupID)
        self._selectedSubMuscle = State(initialValue: card.subMuscleName)
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
                        selectedSubMuscle = nil
                        target = category.defaultTarget
                    }

                    if category.supportsMuscleGroup {
                        Picker("Scope", selection: $selectedMuscleGroupID) {
                            Text("All muscle groups").tag(Optional<UUID>.none)
                            ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                        .onChange(of: selectedMuscleGroupID) { _, _ in
                            selectedSubMuscle = nil
                        }

                        if let groupID = selectedMuscleGroupID,
                           let groupName = repository.muscleGroups.first(where: { $0.id == groupID })?.name,
                           let subMuscles = SeedCatalog.subMuscles[groupName], !subMuscles.isEmpty {
                            Picker("Muscle", selection: $selectedSubMuscle) {
                                Text("Any / All").tag(Optional<String>.none)
                                ForEach(subMuscles, id: \.self) { sub in
                                    Text(sub).tag(Optional(sub))
                                }
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
                        let hasMuscleGroup = selectedMuscleGroupID != nil
                        let metric = category.metricType(forMuscleGroup: hasMuscleGroup)

                        let title: String
                        if hasMuscleGroup,
                           let id = selectedMuscleGroupID,
                           let group = repository.muscleGroups.first(where: { $0.id == id }) {
                            let scopeName = selectedSubMuscle ?? group.name
                            title = "\(scopeName) \(category.suffix)"
                        } else {
                            title = category.displayName
                        }

                        repository.updateGoal(card, metric: metric, target: target, title: title, muscleGroupID: selectedMuscleGroupID, subMuscleName: selectedSubMuscle)
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
