import Foundation
import SwiftData
import SwiftUI

struct WorkoutSectionModel: Identifiable {
    let id: UUID
    let group: MuscleGroupEntity
    var pending: [WeeklyExerciseEntity]
}

struct GoalSnapshot: Identifiable {
    let id: UUID
    let title: String
    let currentValue: Int
    let targetValue: Int
    let card: GoalCardEntity
}

struct WeekSetPoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let sets: Int
}

struct DayActivityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: Int
}

struct MuscleVolumeSummary: Identifiable {
    let id: UUID
    let muscleGroup: MuscleGroupEntity
    let sets: Int
    let exercises: [WeeklyExerciseEntity]
}

struct ExercisePRSnapshot: Identifiable {
    let id = UUID()
    let label: String
    let bestLoad: Double
    let onDate: Date?
}

@MainActor
final class WorkoutRepository: ObservableObject {
    @Published private(set) var settings: AppSettingsEntity?
    @Published private(set) var muscleGroups: [MuscleGroupEntity] = []
    @Published private(set) var exerciseCatalog: [ExerciseEntity] = []
    @Published private(set) var workoutTemplates: [WorkoutTemplateEntity] = []
    @Published private(set) var templateExercises: [WorkoutTemplateExerciseEntity] = []
    @Published private(set) var weeklyExercises: [WeeklyExerciseEntity] = []
    @Published private(set) var completionLogs: [CompletionLogEntity] = []
    @Published private(set) var goalCards: [GoalCardEntity] = []
    @Published var errorMessage: String?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        bootstrapIfNeeded()
        refreshAll()
    }

    var activeWeekStart: Date {
        settings?.activeWeekStartDate ?? Date().startOfWorkoutWeek()
    }

    var activeWeeklyExercises: [WeeklyExerciseEntity] {
        weeklyExercises
            .filter { $0.removedAt == nil && $0.weekStartDate == activeWeekStart }
            .sorted { lhs, rhs in
                if lhs.muscleGroupName == rhs.muscleGroupName {
                    return lhs.orderIndex < rhs.orderIndex
                }
                return groupSortIndex(for: lhs.muscleGroupID, name: lhs.muscleGroupName) < groupSortIndex(for: rhs.muscleGroupID, name: rhs.muscleGroupName)
            }
    }

    var pendingExercises: [WeeklyExerciseEntity] {
        activeWeeklyExercises.filter { $0.completedAt == nil }
    }

    var doneExercises: [WeeklyExerciseEntity] {
        activeWeeklyExercises
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var workoutSections: [WorkoutSectionModel] {
        let grouped = Dictionary(grouping: pendingExercises, by: { $0.muscleGroupID })
        let usedGroupIDs = Set(activeWeeklyExercises.compactMap(\.muscleGroupID))

        let explicitGroups = muscleGroups
            .filter { !$0.isArchived }
            .filter { usedGroupIDs.contains($0.id) || grouped[$0.id] != nil || $0.showsOnWorkout }
            .sorted { $0.orderIndex < $1.orderIndex }

        return explicitGroups.map { group in
            let rows = (grouped[group.id] ?? []).sorted { $0.orderIndex < $1.orderIndex }
            return WorkoutSectionModel(id: group.id, group: group, pending: rows)
        }
    }

    var totalSetsDoneThisWeek: Int {
        activeWeeklyExercises
            .filter { $0.completedAt != nil }
            .compactMap(\.sets)
            .reduce(0, +)
    }

    var completedExercisesThisWeek: Int {
        activeWeeklyExercises.filter { $0.completedAt != nil }.count
    }

    var activeGoalSnapshots: [GoalSnapshot] {
        goalCards
            .filter { !$0.isArchived }
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { card in
                GoalSnapshot(
                    id: card.id,
                    title: goalTitle(for: card),
                    currentValue: currentValue(for: card),
                    targetValue: card.targetValue,
                    card: card
                )
            }
    }

    func doneCountForMuscle(_ muscleGroupID: UUID) -> Int {
        activeWeeklyExercises
            .filter { $0.muscleGroupID == muscleGroupID && $0.completedAt != nil }
            .count
    }

    func weeklySetTrend(weeks: Int = 12) -> [WeekSetPoint] {
        guard weeks > 0 else { return [] }

        var result: [WeekSetPoint] = []
        let calendar = Calendar.workout

        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let week = calendar.date(byAdding: .weekOfYear, value: -offset, to: activeWeekStart) else { continue }
            let total = completionLogs
                .filter { $0.weekStartDate == week }
                .compactMap(\.setsSnapshot)
                .reduce(0, +)
            result.append(WeekSetPoint(weekStart: week, sets: total))
        }

        return result
    }

    func last30DayActivity() -> [DayActivityPoint] {
        let calendar = Calendar.workout
        let today = Date().startOfDayDate()

        return (0..<30).reversed().compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            let sessions = completionLogs.filter { $0.completedAt.startOfDayDate() == date }.count
            return DayActivityPoint(date: date, sessions: sessions)
        }
    }

    func currentWeekMuscleVolume() -> [MuscleVolumeSummary] {
        let grouped = Dictionary(grouping: completionLogs.filter { $0.weekStartDate == activeWeekStart }, by: { $0.muscleGroupID })

        return muscleGroups
            .filter { !$0.isArchived }
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { group in
                let sets = (grouped[group.id] ?? []).compactMap(\.setsSnapshot).reduce(0, +)
                let exercises = activeWeeklyExercises
                    .filter { $0.muscleGroupID == group.id }
                    .sorted { $0.orderIndex < $1.orderIndex }
                return MuscleVolumeSummary(id: group.id, muscleGroup: group, sets: sets, exercises: exercises)
            }
            .filter { !$0.exercises.isEmpty }
    }

    func progressionLogs(for exercise: WeeklyExerciseEntity) -> [CompletionLogEntity] {
        completionLogs
            .filter {
                if let exerciseID = exercise.exerciseID {
                    return $0.exerciseID == exerciseID
                }
                return $0.nameSnapshot.caseInsensitiveCompare(exercise.name) == .orderedSame
            }
            .sorted { $0.completedAt < $1.completedAt }
    }

    func classicPRs() -> [ExercisePRSnapshot] {
        let tags = [
            "Deadlift": "deadlift",
            "Pull Ups": "pull up",
            "Weighted Pull Ups": "weighted pull",
            "Bench Press": "bench press",
            "Squat": "squat"
        ]

        return tags.map { key, token in
            let matches = completionLogs.filter { $0.nameSnapshot.lowercased().contains(token) }
            let best = matches.max { ($0.loadSnapshot ?? 0) < ($1.loadSnapshot ?? 0) }
            return ExercisePRSnapshot(
                label: key,
                bestLoad: best?.loadSnapshot ?? 0,
                onDate: best?.completedAt
            )
        }
    }

    func addMuscleGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = muscleGroups.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame && !$0.isArchived }) {
            existing.showsOnWorkout = true
            saveAndRefresh()
            return
        }

        let nextIndex = (muscleGroups.map(\.orderIndex).max() ?? -1) + 1
        context.insert(MuscleGroupEntity(name: trimmed, orderIndex: nextIndex, showsOnWorkout: true))
        saveAndRefresh()
    }

    func renameMuscleGroup(_ group: MuscleGroupEntity, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        group.name = trimmed

        for row in weeklyExercises where row.muscleGroupID == group.id {
            row.muscleGroupName = trimmed
        }
        for row in templateExercises where row.muscleGroupID == group.id {
            row.muscleGroupName = trimmed
        }
        for item in exerciseCatalog where item.primaryMuscleGroupID == group.id {
            item.primaryMuscleGroupName = trimmed
            item.updatedAt = .now
        }

        saveAndRefresh()
    }

    func addExercise(to group: MuscleGroupEntity) -> WeeklyExerciseEntity {
        group.showsOnWorkout = true
        let nextIndex = nextOrderIndex(in: group.id)
        let row = WeeklyExerciseEntity(
            weekStartDate: activeWeekStart,
            exerciseID: nil,
            name: "",
            muscleGroupID: group.id,
            muscleGroupName: group.name,
            orderIndex: nextIndex,
            sets: nil,
            reps: nil,
            seconds: nil,
            weightKg: nil,
            weightCount: nil
        )
        context.insert(row)
        saveAndRefresh()
        return row
    }

    func addCatalogExerciseToWeek(_ exercise: ExerciseEntity) {
        let group = ensureMuscleGroup(named: exercise.primaryMuscleGroupName)
        group.showsOnWorkout = true
        let nextIndex = nextOrderIndex(in: group.id)

        let row = WeeklyExerciseEntity(
            weekStartDate: activeWeekStart,
            exerciseID: exercise.id,
            name: exercise.name,
            muscleGroupID: group.id,
            muscleGroupName: group.name,
            orderIndex: nextIndex,
            sets: nil,
            reps: nil,
            seconds: nil,
            weightKg: nil,
            weightCount: nil
        )
        context.insert(row)
        saveAndRefresh()
    }

    func addImportedLines(_ lines: [ParsedImportLine], to muscleGroupName: String) {
        let group = ensureMuscleGroup(named: muscleGroupName)
        group.showsOnWorkout = true

        var index = nextOrderIndex(in: group.id)
        for line in lines {
            let row = WeeklyExerciseEntity(
                weekStartDate: activeWeekStart,
                exerciseID: nil,
                name: line.name,
                muscleGroupID: group.id,
                muscleGroupName: group.name,
                orderIndex: index,
                sets: line.sets,
                reps: line.reps,
                seconds: line.seconds,
                weightKg: line.weightKg,
                weightCount: line.weightCount
            )
            context.insert(row)
            index += 1
        }

        saveAndRefresh()
    }

    func addTemplateToWeek(_ template: WorkoutTemplateEntity) {
        let rows = templateExercises
            .filter { $0.templateID == template.id }
            .sorted { $0.orderIndex < $1.orderIndex }

        var nextIndexes: [UUID: Int] = [:]

        for row in rows {
            let group = ensureMuscleGroup(named: row.muscleGroupName)
            group.showsOnWorkout = true
            let nextIndex = nextIndexes[group.id] ?? nextOrderIndex(in: group.id)
            nextIndexes[group.id] = nextIndex + 1

            let weekly = WeeklyExerciseEntity(
                weekStartDate: activeWeekStart,
                exerciseID: row.exerciseID,
                name: row.name,
                muscleGroupID: group.id,
                muscleGroupName: group.name,
                orderIndex: nextIndex,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg,
                weightCount: row.weightCount
            )
            context.insert(weekly)
        }

        saveAndRefresh()
    }

    func updateExercise(_ exercise: WeeklyExerciseEntity) {
        exercise.name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try context.save()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func moveExercise(_ exercise: WeeklyExerciseEntity, to group: MuscleGroupEntity, at index: Int) {
        let previousGroupID = exercise.muscleGroupID
        exercise.muscleGroupID = group.id
        exercise.muscleGroupName = group.name

        if previousGroupID == group.id {
            var rows = activeWeeklyExercises
                .filter { $0.muscleGroupID == group.id && $0.id != exercise.id }
                .sorted { $0.orderIndex < $1.orderIndex }
            let clamped = min(max(index, 0), rows.count)
            rows.insert(exercise, at: clamped)
            for (offset, row) in rows.enumerated() {
                row.orderIndex = offset
            }
        } else {
            normalizeOrder(for: previousGroupID)
            var targetRows = activeWeeklyExercises
                .filter { $0.muscleGroupID == group.id && $0.id != exercise.id }
                .sorted { $0.orderIndex < $1.orderIndex }
            let clamped = min(max(index, 0), targetRows.count)
            targetRows.insert(exercise, at: clamped)
            for (offset, row) in targetRows.enumerated() {
                row.orderIndex = offset
            }
        }

        saveAndRefresh()
    }

    func toggleExerciseCompleted(_ exercise: WeeklyExerciseEntity) {
        if exercise.completedAt == nil {
            exercise.completedAt = .now
            removeCompletionLog(for: exercise)

            context.insert(
                CompletionLogEntity(
                    weekStartDate: exercise.weekStartDate,
                    weeklyExerciseID: exercise.id,
                    exerciseID: exercise.exerciseID,
                    nameSnapshot: exercise.name,
                    muscleGroupID: exercise.muscleGroupID,
                    muscleGroupName: exercise.muscleGroupName,
                    completedAt: .now,
                    setsSnapshot: exercise.sets,
                    repsSnapshot: exercise.reps,
                    secondsSnapshot: exercise.seconds,
                    weightKgSnapshot: exercise.weightKg,
                    weightCountSnapshot: exercise.weightCount,
                    loadSnapshot: load(for: exercise)
                )
            )
        } else {
            exercise.completedAt = nil
            removeCompletionLog(for: exercise)
        }

        saveAndRefresh()
    }

    func removeExerciseFromWeek(_ exercise: WeeklyExerciseEntity) {
        exercise.removedAt = .now
        saveAndRefresh()
    }

    func saveWorkoutToLibrary(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let template = WorkoutTemplateEntity(name: trimmed)
        context.insert(template)

        let rows = activeWeeklyExercises
        for (index, row) in rows.enumerated() {
            let exerciseID = upsertCatalogExercise(from: row)
            let snap = WorkoutTemplateExerciseEntity(
                templateID: template.id,
                exerciseID: exerciseID,
                name: row.name,
                muscleGroupID: row.muscleGroupID,
                muscleGroupName: row.muscleGroupName,
                orderIndex: index,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg,
                weightCount: row.weightCount
            )
            context.insert(snap)
        }

        saveAndRefresh()
    }

    func deleteCurrentWeeklyWorkout() {
        for row in activeWeeklyExercises {
            row.removedAt = .now
            row.completedAt = nil
            removeCompletionLog(for: row)
        }
        saveAndRefresh()
    }

    func startNewWeek() {
        guard let settings else { return }

        let todayStart = Date().startOfWorkoutWeek()
        let nextWeek: Date

        if todayStart <= settings.activeWeekStartDate {
            nextWeek = Calendar.workout.date(byAdding: .day, value: 7, to: settings.activeWeekStartDate) ?? todayStart
        } else {
            nextWeek = todayStart
        }

        let currentRows = activeWeeklyExercises
        settings.activeWeekStartDate = nextWeek

        for row in currentRows {
            let clone = WeeklyExerciseEntity(
                weekStartDate: nextWeek,
                exerciseID: row.exerciseID,
                name: row.name,
                muscleGroupID: row.muscleGroupID,
                muscleGroupName: row.muscleGroupName,
                orderIndex: row.orderIndex,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg,
                weightCount: row.weightCount,
                completedAt: nil,
                removedAt: nil
            )
            context.insert(clone)
        }

        saveAndRefresh()
    }

    func updateWeeklySetGoal(_ value: Int) {
        settings?.weeklySetTarget = value

        if let defaultCard = goalCards.first(where: { $0.isSystem }) {
            defaultCard.targetValue = value
        }

        saveAndRefresh()
    }

    func addCustomGoal(
        metric: GoalMetricType,
        target: Int,
        title: String,
        muscleGroupID: UUID?
    ) {
        let activeCount = goalCards.filter { !$0.isArchived }.count
        guard activeCount < 3 else { return }

        let nextIndex = (goalCards.map(\.orderIndex).max() ?? -1) + 1
        let card = GoalCardEntity(
            title: title,
            metricTypeRaw: metric.rawValue,
            targetValue: target,
            orderIndex: nextIndex,
            muscleGroupID: muscleGroupID,
            isSystem: false,
            isArchived: false
        )
        context.insert(card)
        saveAndRefresh()
    }

    func archiveGoal(_ card: GoalCardEntity) {
        guard !card.isSystem else { return }
        card.isArchived = true
        saveAndRefresh()
    }

    func reorderGoals(from sourceID: UUID, to destinationIndex: Int) {
        var active = goalCards.filter { !$0.isArchived }.sorted { $0.orderIndex < $1.orderIndex }
        guard let sourceIndex = active.firstIndex(where: { $0.id == sourceID }) else { return }

        let clamped = min(max(destinationIndex, 0), active.count - 1)
        let item = active.remove(at: sourceIndex)
        active.insert(item, at: clamped)

        for (index, card) in active.enumerated() {
            card.orderIndex = index
        }

        saveAndRefresh()
    }

    func bootstrapIfNeeded() {
        do {
            let settingsDescriptor = FetchDescriptor<AppSettingsEntity>()
            let settings = try context.fetch(settingsDescriptor)

            if settings.isEmpty {
                let entity = AppSettingsEntity(
                    activeWeekStartDate: Date().startOfWorkoutWeek(),
                    weeklySetTarget: SeedCatalog.defaultWeeklySetGoal,
                    seedVersion: 0
                )
                context.insert(entity)
                try context.save()
            }

            refreshAll()

            guard let settings = self.settings, settings.seedVersion < SeedCatalog.seedVersion else {
                ensureDefaultGoalCard()
                return
            }

            seedLibraryDataIfNeeded()
            settings.seedVersion = SeedCatalog.seedVersion
            ensureDefaultGoalCard()
            try context.save()
            refreshAll()
        } catch {
            errorMessage = "Failed to bootstrap app data: \(error.localizedDescription)"
        }
    }

    func refreshAll() {
        do {
            settings = try context.fetch(FetchDescriptor<AppSettingsEntity>()).first

            let groupDescriptor = FetchDescriptor<MuscleGroupEntity>(
                sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
            )
            muscleGroups = try context.fetch(groupDescriptor)

            let exerciseDescriptor = FetchDescriptor<ExerciseEntity>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            exerciseCatalog = try context.fetch(exerciseDescriptor)

            let templateDescriptor = FetchDescriptor<WorkoutTemplateEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            workoutTemplates = try context.fetch(templateDescriptor).filter { !$0.isArchived }

            let templateExercisesDescriptor = FetchDescriptor<WorkoutTemplateExerciseEntity>(
                sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
            )
            templateExercises = try context.fetch(templateExercisesDescriptor)

            let weekDescriptor = FetchDescriptor<WeeklyExerciseEntity>()
            weeklyExercises = try context.fetch(weekDescriptor)

            let logDescriptor = FetchDescriptor<CompletionLogEntity>(
                sortBy: [SortDescriptor(\.completedAt, order: .forward)]
            )
            completionLogs = try context.fetch(logDescriptor)

            let goalDescriptor = FetchDescriptor<GoalCardEntity>(
                sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
            )
            goalCards = try context.fetch(goalDescriptor)

            ensureDefaultGoalCard()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    private func seedLibraryDataIfNeeded() {
        if workoutTemplates.contains(where: { $0.name == SeedCatalog.defaultTemplateName }) {
            return
        }

        var groupLookup: [String: MuscleGroupEntity] = [:]
        for (index, name) in SeedCatalog.muscleGroups.enumerated() {
            let group = MuscleGroupEntity(name: name, orderIndex: index)
            context.insert(group)
            groupLookup[name] = group
        }

        let template = WorkoutTemplateEntity(name: SeedCatalog.defaultTemplateName)
        context.insert(template)

        for (index, seed) in SeedCatalog.exercises.enumerated() {
            let group = groupLookup[seed.muscleGroup] ?? ensureMuscleGroup(named: seed.muscleGroup)

            let exercise = ExerciseEntity(
                name: seed.name,
                primaryMuscleGroupID: group.id,
                primaryMuscleGroupName: seed.muscleGroup
            )
            context.insert(exercise)

            let item = WorkoutTemplateExerciseEntity(
                templateID: template.id,
                exerciseID: exercise.id,
                name: seed.name,
                muscleGroupID: group.id,
                muscleGroupName: seed.muscleGroup,
                orderIndex: index,
                sets: seed.sets,
                reps: seed.reps,
                seconds: seed.seconds,
                weightKg: seed.weightKg,
                weightCount: seed.weightCount
            )
            context.insert(item)
        }
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            refreshAll()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    private func ensureDefaultGoalCard() {
        if goalCards.contains(where: { $0.isSystem && !$0.isArchived }) {
            return
        }

        let target = settings?.weeklySetTarget ?? SeedCatalog.defaultWeeklySetGoal
        let card = GoalCardEntity(
            title: "Total Sets",
            metricTypeRaw: GoalMetricType.totalSets.rawValue,
            targetValue: target,
            orderIndex: 0,
            muscleGroupID: nil,
            isSystem: true,
            isArchived: false
        )
        context.insert(card)

        do {
            try context.save()
            goalCards = try context.fetch(FetchDescriptor<GoalCardEntity>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)]))
        } catch {
            errorMessage = "Failed to initialize default goals"
        }
    }

    private func ensureMuscleGroup(named name: String) -> MuscleGroupEntity {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = muscleGroups.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame && !$0.isArchived }) {
            return existing
        }

        let nextIndex = (muscleGroups.map(\.orderIndex).max() ?? -1) + 1
        let group = MuscleGroupEntity(name: trimmed, orderIndex: nextIndex)
        context.insert(group)
        return group
    }

    private func upsertCatalogExercise(from weekly: WeeklyExerciseEntity) -> UUID {
        let trimmed = weekly.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = exerciseCatalog.first(where: {
            !$0.isArchived
            && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
            && $0.primaryMuscleGroupName.caseInsensitiveCompare(weekly.muscleGroupName) == .orderedSame
        }) {
            existing.updatedAt = .now
            return existing.id
        }

        let newExercise = ExerciseEntity(
            name: trimmed,
            primaryMuscleGroupID: weekly.muscleGroupID,
            primaryMuscleGroupName: weekly.muscleGroupName
        )
        context.insert(newExercise)
        return newExercise.id
    }

    private func removeCompletionLog(for exercise: WeeklyExerciseEntity) {
        let logs = completionLogs.filter { $0.weeklyExerciseID == exercise.id && $0.weekStartDate == exercise.weekStartDate }
        for log in logs {
            context.delete(log)
        }
    }

    private func nextOrderIndex(in groupID: UUID?) -> Int {
        let maxValue = activeWeeklyExercises
            .filter { $0.muscleGroupID == groupID }
            .map(\.orderIndex)
            .max() ?? -1
        return maxValue + 1
    }

    private func normalizeOrder(for groupID: UUID?) {
        let rows = activeWeeklyExercises
            .filter { $0.muscleGroupID == groupID }
            .sorted { $0.orderIndex < $1.orderIndex }

        for (index, row) in rows.enumerated() {
            row.orderIndex = index
        }
    }

    private func groupSortIndex(for groupID: UUID?, name: String) -> Int {
        if let groupID, let group = muscleGroups.first(where: { $0.id == groupID }) {
            return group.orderIndex
        }
        return muscleGroups.count + abs(name.hashValue % 10_000)
    }

    private func goalTitle(for card: GoalCardEntity) -> String {
        if card.metricType == .muscleGroupSets,
           let muscleGroupID = card.muscleGroupID,
           let group = muscleGroups.first(where: { $0.id == muscleGroupID }) {
            return group.name
        }

        return card.title
    }

    private func currentValue(for card: GoalCardEntity) -> Int {
        switch card.metricType {
        case .totalSets:
            return totalSetsDoneThisWeek
        case .exercisesDone:
            return completedExercisesThisWeek
        case .muscleGroupSets:
            let id = card.muscleGroupID
            return completionLogs
                .filter { $0.weekStartDate == activeWeekStart && $0.muscleGroupID == id }
                .compactMap(\.setsSnapshot)
                .reduce(0, +)
        }
    }

    private func load(for exercise: WeeklyExerciseEntity) -> Double? {
        guard let reps = exercise.reps,
              let kg = exercise.weightKg else { return nil }
        let count = Double(exercise.weightCount ?? 1)
        return Double(reps) * kg * count
    }
}
