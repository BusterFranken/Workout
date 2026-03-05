import Foundation
import SwiftData
import SwiftUI

enum TemplateAddBehavior {
    case addAllUnique
    case replaceCurrent
}

enum TrackingWidgetID: String, CaseIterable, Identifiable {
    case weeklySets
    case workoutDays
    case muscleTrend
    case currentWeekByMuscle
    case bodyMetrics
    case classicPRs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weeklySets:
            return "Sets Per Week"
        case .workoutDays:
            return "Workout Days"
        case .muscleTrend:
            return "Volume By Muscle"
        case .currentWeekByMuscle:
            return "Current Week By Muscle"
        case .bodyMetrics:
            return "Body Metrics"
        case .classicPRs:
            return "Classic PR Tracking"
        }
    }
}

struct WorkoutSectionModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let mode: WorkoutViewMode
    let muscleGroup: MuscleGroupEntity?
    let rows: [WeeklyExerciseEntity]
    let doneCount: Int
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

struct MuscleExerciseProgress: Identifiable {
    let id: UUID
    let exercise: WeeklyExerciseEntity
    let doneSets: Int
}

struct MuscleVolumeSummary: Identifiable {
    let id: UUID
    let muscleGroup: MuscleGroupEntity
    let sets: Int
    let exerciseProgress: [MuscleExerciseProgress]
}

struct MuscleTrendPoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let muscleGroup: String
    let sets: Int
}

struct ExercisePRSnapshot: Identifiable {
    let id = UUID()
    let label: String
    let bestLoad: Double
    let onDate: Date?
}

struct PRPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let source: String
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
    @Published private(set) var bodyMetricEntries: [BodyMetricEntryEntity] = []
    @Published private(set) var prRecords: [PRRecordEntity] = []
    @Published var errorMessage: String?

    private let context: ModelContext

    private let customSlots = ["A", "B", "C", "D", "E"]
    private let weekdayHeaders: [(Int, String)] = [
        (1, "Monday"),
        (2, "Tuesday"),
        (3, "Wednesday"),
        (4, "Thursday"),
        (5, "Friday"),
        (6, "Saturday (Rest)"),
        (7, "Sunday (Rest)")
    ]

    init(context: ModelContext) {
        self.context = context
        bootstrapIfNeeded()
        refreshAll()
    }

    var activeWeekStart: Date {
        settings?.activeWeekStartDate ?? Date().startOfWorkoutWeek()
    }

    var activeWorkoutName: String {
        settings?.activeWorkoutName ?? "My Weekly Workout"
    }

    var workoutViewMode: WorkoutViewMode {
        settings?.workoutViewMode ?? .muscleGroups
    }

    var unitSystem: UnitSystem {
        settings?.unitSystem ?? .kg
    }

    var themePreference: AppThemePreference {
        settings?.themePreference ?? .system
    }

    var activeWeeklyExercises: [WeeklyExerciseEntity] {
        weeklyExercises
            .filter { $0.removedAt == nil && $0.weekStartDate == activeWeekStart }
    }

    var pendingExercises: [WeeklyExerciseEntity] {
        activeWeeklyExercises.filter { $0.completedAt == nil }
    }

    var doneExercises: [WeeklyExerciseEntity] {
        activeWeeklyExercises
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var hasAnyActiveExercise: Bool {
        !activeWeeklyExercises.isEmpty
    }

    var shouldShowAddHeadingHint: Bool {
        workoutViewMode == .muscleGroups && workoutSections.count < 5
    }

    var trackingWidgetOrder: [TrackingWidgetID] {
        let raw = settings?.trackingWidgetOrderRaw ?? defaultTrackingWidgetOrderRaw
        let configured = raw
            .split(separator: ",")
            .compactMap { TrackingWidgetID(rawValue: String($0)) }
        let missing = TrackingWidgetID.allCases.filter { !configured.contains($0) }
        return configured + missing
    }

    var workoutSections: [WorkoutSectionModel] {
        switch workoutViewMode {
        case .muscleGroups:
            return muscleGroupSections()
        case .weekdays:
            return weekdaySections()
        case .custom:
            return customSections()
        }
    }

    var totalSetsDoneThisWeek: Int {
        doneExercises.compactMap(\.sets).reduce(0, +)
    }

    var completedExercisesThisWeek: Int {
        doneExercises.count
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

    func doneCountForSection(_ section: WorkoutSectionModel) -> Int {
        section.doneCount
    }

    func weeklySetTrend(weeks: Int = 12) -> [WeekSetPoint] {
        guard weeks > 0 else { return [] }
        let calendar = Calendar.workout

        return stride(from: weeks - 1, through: 0, by: -1).compactMap { offset in
            guard let week = calendar.date(byAdding: .weekOfYear, value: -offset, to: activeWeekStart) else { return nil }
            let total = completionLogs
                .filter { $0.weekStartDate == week }
                .compactMap(\.setsSnapshot)
                .reduce(0, +)
            return WeekSetPoint(weekStart: week, sets: total)
        }
    }

    func allTimeActivity() -> [DayActivityPoint] {
        let calendar = Calendar.workout
        let today = Date().startOfDayDate()
        let firstLogDate = completionLogs.first?.completedAt.startOfDayDate()
            ?? calendar.date(byAdding: .day, value: -180, to: today)
            ?? today

        var points: [DayActivityPoint] = []
        var cursor = firstLogDate

        while cursor <= today {
            let sessions = completionLogs.filter { $0.completedAt.startOfDayDate() == cursor }.count
            points.append(DayActivityPoint(date: cursor, sessions: sessions))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return points
    }

    func currentWeekMuscleVolume() -> [MuscleVolumeSummary] {
        let thisWeek = completionLogs.filter { $0.weekStartDate == activeWeekStart }

        var setsByGroupName: [String: Int] = [:]
        var setsByGroupAndExercise: [String: [UUID: Int]] = [:]

        for log in thisWeek {
            let sets = log.setsSnapshot ?? 0
            let groups = [log.muscleGroupName] + parseCSV(log.secondaryMuscleGroupsRaw)

            for groupName in groups {
                let normalized = normalizeGroupName(groupName)
                guard !normalized.isEmpty else { continue }
                setsByGroupName[normalized, default: 0] += sets
                setsByGroupAndExercise[normalized, default: [:]][log.weeklyExerciseID, default: 0] += sets
            }
        }

        return muscleGroups
            .filter { !$0.isArchived }
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { group in
                let key = normalizeGroupName(group.name)
                let groupTotal = setsByGroupName[key] ?? 0

                let exerciseRows = activeWeeklyExercises.filter { exercise in
                    if normalizeGroupName(exercise.muscleGroupName) == key {
                        return true
                    }
                    return parseCSV(exercise.secondaryMuscleGroupsRaw)
                        .map(normalizeGroupName)
                        .contains(key)
                }
                .sorted { $0.orderIndex < $1.orderIndex }

                let progress = exerciseRows.map { exercise in
                    let doneSets = setsByGroupAndExercise[key]?[exercise.id] ?? 0
                    return MuscleExerciseProgress(
                        id: exercise.id,
                        exercise: exercise,
                        doneSets: doneSets
                    )
                }
                .filter { $0.doneSets > 0 }

                return MuscleVolumeSummary(
                    id: group.id,
                    muscleGroup: group,
                    sets: groupTotal,
                    exerciseProgress: progress
                )
            }
            .filter { !$0.exerciseProgress.isEmpty && $0.sets > 0 }
    }

    func muscleVolumeTrend(weeks: Int = 10) -> [MuscleTrendPoint] {
        guard weeks > 0 else { return [] }
        let calendar = Calendar.workout

        let activeGroups = muscleGroups.filter { !$0.isArchived }
        var points: [MuscleTrendPoint] = []

        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let week = calendar.date(byAdding: .weekOfYear, value: -offset, to: activeWeekStart) else { continue }

            for group in activeGroups {
                let groupKey = normalizeGroupName(group.name)
                let sum = completionLogs
                    .filter { $0.weekStartDate == week }
                    .reduce(0) { partial, log in
                        guard let sets = log.setsSnapshot else { return partial }
                        let groups = [log.muscleGroupName] + parseCSV(log.secondaryMuscleGroupsRaw)
                        let normalized = groups.map(normalizeGroupName)
                        return normalized.contains(groupKey) ? (partial + sets) : partial
                    }

                points.append(
                    MuscleTrendPoint(
                        weekStart: week,
                        muscleGroup: group.name,
                        sets: sum
                    )
                )
            }
        }

        return points
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

        return tags.map { label, token in
            let logBest = completionLogs
                .filter { $0.nameSnapshot.lowercased().contains(token) }
                .max { ($0.loadSnapshot ?? 0) < ($1.loadSnapshot ?? 0) }

            let manualBest = prRecords
                .filter { $0.exerciseLabel.caseInsensitiveCompare(label) == .orderedSame }
                .max { $0.value < $1.value }

            let logValue = logBest?.loadSnapshot ?? 0
            let manualValue = manualBest?.value ?? 0

            if manualValue > logValue {
                return ExercisePRSnapshot(label: label, bestLoad: manualValue, onDate: manualBest?.recordedAt)
            }

            return ExercisePRSnapshot(label: label, bestLoad: logValue, onDate: logBest?.completedAt)
        }
    }

    func prHistory(for label: String) -> [PRPoint] {
        let token = label.lowercased()

        let fromLogs = completionLogs
            .filter { $0.nameSnapshot.lowercased().contains(token) }
            .compactMap { log -> PRPoint? in
                guard let value = log.loadSnapshot, value > 0 else { return nil }
                return PRPoint(date: log.completedAt, value: value, source: "Auto")
            }

        let fromManual = prRecords
            .filter { $0.exerciseLabel.caseInsensitiveCompare(label) == .orderedSame }
            .map { PRPoint(date: $0.recordedAt, value: $0.value, source: "Manual") }

        return (fromLogs + fromManual).sorted { $0.date < $1.date }
    }

    func addPRRecord(label: String, value: Double, notes: String = "") {
        guard value > 0 else { return }
        context.insert(PRRecordEntity(exerciseLabel: label, value: value, notes: notes))
        saveAndRefresh()
    }

    func bodyMetricHistory(kind: BodyMetricKind, lastDays: Int = 30) -> [BodyMetricEntryEntity] {
        let startDate = Calendar.workout.date(byAdding: .day, value: -lastDays, to: .now) ?? .distantPast
        return bodyMetricEntries
            .filter { $0.kind == kind && $0.recordedAt >= startDate }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    func latestBodyMetric(kind: BodyMetricKind) -> BodyMetricEntryEntity? {
        bodyMetricEntries
            .filter { $0.kind == kind }
            .max { $0.recordedAt < $1.recordedAt }
    }

    func addBodyMetric(kind: BodyMetricKind, value: Double) {
        guard value > 0 else { return }
        context.insert(BodyMetricEntryEntity(kindRaw: kind.rawValue, value: value))
        saveAndRefresh()
    }

    func updateWorkoutName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        settings?.activeWorkoutName = trimmed
        saveAndRefresh()
    }

    func updateWorkoutViewMode(_ mode: WorkoutViewMode) {
        settings?.workoutViewMode = mode
        saveAndRefresh()
    }

    func updateUnitSystem(_ unit: UnitSystem) {
        settings?.unitSystem = unit
        saveAndRefresh()
    }

    func updateThemePreference(_ preference: AppThemePreference) {
        settings?.themePreference = preference
        saveAndRefresh()
    }

    func reorderTrackingWidgets(from source: TrackingWidgetID, to destinationIndex: Int) {
        var order = trackingWidgetOrder
        guard let sourceIndex = order.firstIndex(of: source) else { return }
        let item = order.remove(at: sourceIndex)
        let clamped = min(max(destinationIndex, 0), order.count)
        order.insert(item, at: clamped)
        settings?.trackingWidgetOrderRaw = order.map(\.rawValue).joined(separator: ",")
        saveAndRefresh()
    }

    func addMuscleGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = muscleGroups.first(where: { normalizeGroupName($0.name) == normalizeGroupName(trimmed) && !$0.isArchived }) {
            existing.showsOnWorkout = true
            saveAndRefresh()
            return
        }

        let nextIndex = (muscleGroups.map(\.orderIndex).max() ?? -1) + 1
        context.insert(MuscleGroupEntity(name: trimmed, orderIndex: nextIndex, showsOnWorkout: true))
        saveAndRefresh()
    }

    func addHeadingForCurrentView() {
        guard workoutViewMode == .muscleGroups else { return }
        let nextNumber = workoutSections.count + 1
        addMuscleGroup(name: "Heading \(nextNumber)")
    }

    func renameMuscleGroup(_ group: MuscleGroupEntity, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let oldNormalized = normalizeGroupName(group.name)
        group.name = trimmed

        for row in weeklyExercises where row.muscleGroupID == group.id {
            row.muscleGroupName = trimmed
        }

        for row in weeklyExercises where parseCSV(row.secondaryMuscleGroupsRaw).map(normalizeGroupName).contains(oldNormalized) {
            let updated = parseCSV(row.secondaryMuscleGroupsRaw).map {
                normalizeGroupName($0) == oldNormalized ? trimmed : $0
            }
            row.secondaryMuscleGroupsRaw = updated.joined(separator: ",")
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

    func addExercise(to section: WorkoutSectionModel) -> WeeklyExerciseEntity {
        let defaultGroup = section.muscleGroup ?? ensureDefaultExerciseGroup()
        defaultGroup.showsOnWorkout = true

        let nextIndex = nextOrderIndex(in: section)

        let row = WeeklyExerciseEntity(
            weekStartDate: activeWeekStart,
            exerciseID: nil,
            name: "",
            muscleGroupID: defaultGroup.id,
            muscleGroupName: defaultGroup.name,
            secondaryMuscleGroupsRaw: "",
            notes: "",
            weekdayIndex: section.mode == .weekdays ? parseWeekday(section.id) : nil,
            customSlot: section.mode == .custom ? parseCustomSlot(section.id) : nil,
            orderIndex: nextIndex,
            sets: nil,
            reps: nil,
            seconds: nil,
            weightKg: nil
        )

        context.insert(row)
        saveAndRefresh()
        return row
    }

    func addCatalogExerciseToWeek(_ exercise: ExerciseEntity) {
        let group = ensureMuscleGroup(named: exercise.primaryMuscleGroupName)
        group.showsOnWorkout = true

        let row = WeeklyExerciseEntity(
            weekStartDate: activeWeekStart,
            exerciseID: exercise.id,
            name: exercise.name,
            muscleGroupID: group.id,
            muscleGroupName: group.name,
            secondaryMuscleGroupsRaw: exercise.secondaryMuscleGroupsRaw,
            notes: exercise.notes,
            orderIndex: nextOrderIndexInMuscleGroup(group.id),
            sets: nil,
            reps: nil,
            seconds: nil,
            weightKg: nil
        )

        context.insert(row)
        saveAndRefresh()
    }

    func addImportedLines(_ lines: [ParsedImportLine], to muscleGroupName: String) {
        let group = ensureMuscleGroup(named: muscleGroupName)
        group.showsOnWorkout = true

        var index = nextOrderIndexInMuscleGroup(group.id)
        for line in lines {
            let row = WeeklyExerciseEntity(
                weekStartDate: activeWeekStart,
                exerciseID: nil,
                name: line.name,
                muscleGroupID: group.id,
                muscleGroupName: group.name,
                secondaryMuscleGroupsRaw: "",
                notes: "",
                orderIndex: index,
                sets: line.sets,
                reps: line.reps,
                seconds: line.seconds,
                weightKg: line.weightKg
            )
            context.insert(row)
            index += 1
        }

        saveAndRefresh()
    }

    func addTemplateToWeek(_ template: WorkoutTemplateEntity, behavior: TemplateAddBehavior) {
        let hadExercisesBeforeAdd = hasAnyActiveExercise

        if behavior == .replaceCurrent {
            clearCurrentWorkoutRows()
            settings?.activeWorkoutName = template.name
        }

        let existingNames = Set(activeWeeklyExercises.map { normalizedKey($0.name) })
        var mutableExisting = existingNames

        let rows = templateExercises
            .filter { $0.templateID == template.id }
            .sorted { $0.orderIndex < $1.orderIndex }

        var nextIndexes: [UUID: Int] = [:]

        for row in rows {
            if behavior == .addAllUnique {
                let key = normalizedKey(row.name)
                if mutableExisting.contains(key) {
                    continue
                }
                mutableExisting.insert(key)
            }

            let group = ensureMuscleGroup(named: row.muscleGroupName)
            group.showsOnWorkout = true
            let nextIndex = nextIndexes[group.id] ?? nextOrderIndexInMuscleGroup(group.id)
            nextIndexes[group.id] = nextIndex + 1

            let weekly = WeeklyExerciseEntity(
                weekStartDate: activeWeekStart,
                exerciseID: row.exerciseID,
                name: row.name,
                muscleGroupID: group.id,
                muscleGroupName: group.name,
                secondaryMuscleGroupsRaw: row.secondaryMuscleGroupsRaw,
                notes: row.notes,
                weekdayIndex: row.weekdayIndex,
                customSlot: row.customSlot,
                orderIndex: nextIndex,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg
            )
            context.insert(weekly)
        }

        if !hadExercisesBeforeAdd || behavior == .replaceCurrent {
            settings?.activeWorkoutName = template.name
        }

        saveAndRefresh()
    }

    func updateExercise(_ exercise: WeeklyExerciseEntity, refresh: Bool = false) {
        exercise.name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if refresh {
            saveAndRefresh()
            return
        }

        do {
            try context.save()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func moveExercise(sourceID: UUID, toSectionID sectionID: String, at index: Int) {
        guard let exercise = activeWeeklyExercises.first(where: { $0.id == sourceID }) else { return }

        switch workoutViewMode {
        case .muscleGroups:
            guard let groupID = UUID(uuidString: sectionID),
                  let group = muscleGroups.first(where: { $0.id == groupID }) else {
                return
            }
            moveExercise(exercise, toMuscleGroup: group, at: index)
        case .weekdays:
            guard let day = parseWeekday(sectionID) else { return }
            moveExercise(exercise, toWeekday: day, at: index)
        case .custom:
            guard let slot = parseCustomSlot(sectionID) else { return }
            moveExercise(exercise, toCustomSlot: slot, at: index)
        }
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
                    secondaryMuscleGroupsRaw: exercise.secondaryMuscleGroupsRaw,
                    completedAt: .now,
                    setsSnapshot: exercise.sets,
                    repsSnapshot: exercise.reps,
                    secondsSnapshot: exercise.seconds,
                    weightKgSnapshot: exercise.weightKg,
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
        removeCompletionLog(for: exercise)
        saveAndRefresh()
    }

    func saveWorkoutToLibrary(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        settings?.activeWorkoutName = trimmed

        let template = WorkoutTemplateEntity(name: trimmed)
        context.insert(template)

        let rows = activeWeeklyExercises.sorted { $0.orderIndex < $1.orderIndex }
        for (index, row) in rows.enumerated() {
            let exerciseID = upsertCatalogExercise(from: row)

            let snap = WorkoutTemplateExerciseEntity(
                templateID: template.id,
                exerciseID: exerciseID,
                name: row.name,
                muscleGroupID: row.muscleGroupID,
                muscleGroupName: row.muscleGroupName,
                secondaryMuscleGroupsRaw: row.secondaryMuscleGroupsRaw,
                notes: row.notes,
                weekdayIndex: row.weekdayIndex,
                customSlot: row.customSlot,
                orderIndex: index,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg
            )
            context.insert(snap)
        }

        saveAndRefresh()
    }

    func deleteCurrentWeeklyWorkout() {
        clearCurrentWorkoutRows()
        saveAndRefresh()
    }

    func startFromScratchWorkout() {
        if !activeWeeklyExercises.isEmpty {
            return
        }

        settings?.activeWorkoutName = "Start From Scratch"

        if let first = muscleGroups.first(where: { !$0.isArchived }) {
            first.showsOnWorkout = true
        } else {
            context.insert(MuscleGroupEntity(name: "Heading 1", orderIndex: 0, showsOnWorkout: true))
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
                secondaryMuscleGroupsRaw: row.secondaryMuscleGroupsRaw,
                notes: row.notes,
                weekdayIndex: row.weekdayIndex,
                customSlot: row.customSlot,
                orderIndex: row.orderIndex,
                sets: row.sets,
                reps: row.reps,
                seconds: row.seconds,
                weightKg: row.weightKg,
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

    func addCustomGoal(metric: GoalMetricType, target: Int, title: String, muscleGroupID: UUID?) {
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
            let allSettings = try context.fetch(settingsDescriptor)

            if allSettings.isEmpty {
                let entity = AppSettingsEntity(
                    activeWeekStartDate: Date().startOfWorkoutWeek(),
                    activeWorkoutName: "My Weekly Workout",
                    workoutViewModeRaw: WorkoutViewMode.muscleGroups.rawValue,
                    weeklySetTarget: SeedCatalog.defaultWeeklySetGoal,
                    unitSystemRaw: UnitSystem.kg.rawValue,
                    themePreferenceRaw: AppThemePreference.system.rawValue,
                    trackingWidgetOrderRaw: defaultTrackingWidgetOrderRaw,
                    seedVersion: 0
                )
                context.insert(entity)
                try context.save()
            }

            refreshAll()

            guard let settings = self.settings,
                  settings.seedVersion < SeedCatalog.seedVersion
            else {
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

            muscleGroups = try context.fetch(
                FetchDescriptor<MuscleGroupEntity>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)])
            )

            exerciseCatalog = try context.fetch(
                FetchDescriptor<ExerciseEntity>(sortBy: [SortDescriptor(\.name, order: .forward)])
            )

            workoutTemplates = try context.fetch(
                FetchDescriptor<WorkoutTemplateEntity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            ).filter { !$0.isArchived }

            templateExercises = try context.fetch(
                FetchDescriptor<WorkoutTemplateExerciseEntity>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)])
            )

            weeklyExercises = try context.fetch(FetchDescriptor<WeeklyExerciseEntity>())

            completionLogs = try context.fetch(
                FetchDescriptor<CompletionLogEntity>(sortBy: [SortDescriptor(\.completedAt, order: .forward)])
            )

            goalCards = try context.fetch(
                FetchDescriptor<GoalCardEntity>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)])
            )

            bodyMetricEntries = try context.fetch(
                FetchDescriptor<BodyMetricEntryEntity>(sortBy: [SortDescriptor(\.recordedAt, order: .forward)])
            )

            prRecords = try context.fetch(
                FetchDescriptor<PRRecordEntity>(sortBy: [SortDescriptor(\.recordedAt, order: .forward)])
            )

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
            groupLookup[normalizeGroupName(name)] = group
        }

        let template = WorkoutTemplateEntity(name: SeedCatalog.defaultTemplateName)
        context.insert(template)

        for (index, seed) in SeedCatalog.exercises.enumerated() {
            let key = normalizeGroupName(seed.muscleGroup)
            let group = groupLookup[key] ?? ensureMuscleGroup(named: seed.muscleGroup)
            for secondary in seed.secondaryMuscleGroups where !secondary.isEmpty {
                _ = ensureMuscleGroup(named: secondary)
            }

            let exercise = ExerciseEntity(
                name: seed.name,
                primaryMuscleGroupID: group.id,
                primaryMuscleGroupName: seed.muscleGroup,
                secondaryMuscleGroupsRaw: seed.secondaryMuscleGroups.joined(separator: ","),
                synonymsRaw: seed.synonyms.joined(separator: ","),
                notes: seed.notes
            )
            context.insert(exercise)

            let item = WorkoutTemplateExerciseEntity(
                templateID: template.id,
                exerciseID: exercise.id,
                name: seed.name,
                muscleGroupID: group.id,
                muscleGroupName: seed.muscleGroup,
                secondaryMuscleGroupsRaw: seed.secondaryMuscleGroups.joined(separator: ","),
                notes: seed.notes,
                weekdayIndex: seed.weekdayIndex,
                customSlot: seed.customSlot,
                orderIndex: index,
                sets: seed.sets,
                reps: seed.reps,
                seconds: seed.seconds,
                weightKg: seed.weightKg
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
            goalCards = try context.fetch(
                FetchDescriptor<GoalCardEntity>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)])
            )
        } catch {
            errorMessage = "Failed to initialize default goals"
        }
    }

    private func clearCurrentWorkoutRows() {
        for row in activeWeeklyExercises {
            row.removedAt = .now
            row.completedAt = nil
            removeCompletionLog(for: row)
        }
    }

    private func ensureMuscleGroup(named name: String) -> MuscleGroupEntity {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = muscleGroups.first(where: {
            normalizeGroupName($0.name) == normalizeGroupName(trimmed)
            && !$0.isArchived
        }) {
            return existing
        }

        let nextIndex = (muscleGroups.map(\.orderIndex).max() ?? -1) + 1
        let group = MuscleGroupEntity(name: trimmed, orderIndex: nextIndex)
        context.insert(group)
        return group
    }

    private func ensureDefaultExerciseGroup() -> MuscleGroupEntity {
        if let first = muscleGroups.first(where: { !$0.isArchived && $0.showsOnWorkout }) {
            return first
        }
        return ensureMuscleGroup(named: "General")
    }

    private func upsertCatalogExercise(from weekly: WeeklyExerciseEntity) -> UUID {
        let trimmed = weekly.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = exerciseCatalog.first(where: {
            !$0.isArchived
            && normalizedKey($0.name) == normalizedKey(trimmed)
            && normalizeGroupName($0.primaryMuscleGroupName) == normalizeGroupName(weekly.muscleGroupName)
        }) {
            existing.secondaryMuscleGroupsRaw = weekly.secondaryMuscleGroupsRaw
            existing.notes = weekly.notes
            existing.updatedAt = .now
            return existing.id
        }

        let newExercise = ExerciseEntity(
            name: trimmed,
            primaryMuscleGroupID: weekly.muscleGroupID,
            primaryMuscleGroupName: weekly.muscleGroupName,
            secondaryMuscleGroupsRaw: weekly.secondaryMuscleGroupsRaw,
            notes: weekly.notes
        )
        context.insert(newExercise)
        return newExercise.id
    }

    private func removeCompletionLog(for exercise: WeeklyExerciseEntity) {
        let logs = completionLogs.filter {
            $0.weeklyExerciseID == exercise.id
            && $0.weekStartDate == exercise.weekStartDate
        }
        for log in logs {
            context.delete(log)
        }
    }

    private func nextOrderIndex(in section: WorkoutSectionModel) -> Int {
        let maxValue = section.rows.map(\.orderIndex).max() ?? -1
        return maxValue + 1
    }

    private func nextOrderIndexInMuscleGroup(_ groupID: UUID?) -> Int {
        let maxValue = activeWeeklyExercises
            .filter { $0.muscleGroupID == groupID }
            .map(\.orderIndex)
            .max() ?? -1
        return maxValue + 1
    }

    private func moveExercise(_ exercise: WeeklyExerciseEntity, toMuscleGroup group: MuscleGroupEntity, at index: Int) {
        let previousGroupID = exercise.muscleGroupID
        exercise.muscleGroupID = group.id
        exercise.muscleGroupName = group.name

        if previousGroupID == group.id {
            reorderRowsInMuscleGroup(group.id, inserting: exercise, at: index)
        } else {
            normalizeOrderInMuscleGroup(previousGroupID)
            reorderRowsInMuscleGroup(group.id, inserting: exercise, at: index)
        }

        saveAndRefresh()
    }

    private func moveExercise(_ exercise: WeeklyExerciseEntity, toWeekday day: Int, at index: Int) {
        let previousDay = exercise.weekdayIndex ?? 1
        exercise.weekdayIndex = day

        if previousDay == day {
            reorderRowsInWeekday(day, inserting: exercise, at: index)
        } else {
            normalizeOrderInWeekday(previousDay)
            reorderRowsInWeekday(day, inserting: exercise, at: index)
        }

        saveAndRefresh()
    }

    private func moveExercise(_ exercise: WeeklyExerciseEntity, toCustomSlot slot: String, at index: Int) {
        let previousSlot = (exercise.customSlot ?? "A")
        exercise.customSlot = slot

        if previousSlot == slot {
            reorderRowsInCustomSlot(slot, inserting: exercise, at: index)
        } else {
            normalizeOrderInCustomSlot(previousSlot)
            reorderRowsInCustomSlot(slot, inserting: exercise, at: index)
        }

        saveAndRefresh()
    }

    private func reorderRowsInMuscleGroup(_ groupID: UUID?, inserting exercise: WeeklyExerciseEntity, at index: Int) {
        var rows = activeWeeklyExercises
            .filter { $0.muscleGroupID == groupID && $0.id != exercise.id && $0.completedAt == nil }
            .sorted { $0.orderIndex < $1.orderIndex }

        let clamped = min(max(index, 0), rows.count)
        rows.insert(exercise, at: clamped)

        for (offset, row) in rows.enumerated() {
            row.orderIndex = offset
        }
    }

    private func reorderRowsInWeekday(_ day: Int?, inserting exercise: WeeklyExerciseEntity, at index: Int) {
        let normalizedDay = day ?? 1
        var rows = pendingExercises
            .filter { ($0.weekdayIndex ?? 1) == normalizedDay && $0.id != exercise.id }
            .sorted { $0.orderIndex < $1.orderIndex }

        let clamped = min(max(index, 0), rows.count)
        rows.insert(exercise, at: clamped)

        for (offset, row) in rows.enumerated() {
            row.orderIndex = offset
        }
    }

    private func reorderRowsInCustomSlot(_ slot: String?, inserting exercise: WeeklyExerciseEntity, at index: Int) {
        let normalizedSlot = normalizeGroupName(slot ?? "A")
        var rows = pendingExercises
            .filter { normalizeGroupName($0.customSlot ?? "A") == normalizedSlot && $0.id != exercise.id }
            .sorted { $0.orderIndex < $1.orderIndex }

        let clamped = min(max(index, 0), rows.count)
        rows.insert(exercise, at: clamped)

        for (offset, row) in rows.enumerated() {
            row.orderIndex = offset
        }
    }

    private func normalizeOrderInMuscleGroup(_ groupID: UUID?) {
        let rows = pendingExercises
            .filter { $0.muscleGroupID == groupID }
            .sorted { $0.orderIndex < $1.orderIndex }

        for (index, row) in rows.enumerated() {
            row.orderIndex = index
        }
    }

    private func normalizeOrderInWeekday(_ day: Int?) {
        let normalizedDay = day ?? 1
        let rows = pendingExercises
            .filter { ($0.weekdayIndex ?? 1) == normalizedDay }
            .sorted { $0.orderIndex < $1.orderIndex }

        for (index, row) in rows.enumerated() {
            row.orderIndex = index
        }
    }

    private func normalizeOrderInCustomSlot(_ slot: String?) {
        let normalizedSlot = normalizeGroupName(slot ?? "A")
        let rows = pendingExercises
            .filter { normalizeGroupName($0.customSlot ?? "A") == normalizedSlot }
            .sorted { $0.orderIndex < $1.orderIndex }

        for (index, row) in rows.enumerated() {
            row.orderIndex = index
        }
    }

    private func muscleGroupSections() -> [WorkoutSectionModel] {
        let pendingByGroup = Dictionary(grouping: pendingExercises, by: { $0.muscleGroupID })
        let doneByGroup = Dictionary(grouping: doneExercises, by: { $0.muscleGroupID })
        let usedGroupIDs = Set(activeWeeklyExercises.compactMap(\.muscleGroupID))

        let groups = muscleGroups
            .filter { !$0.isArchived }
            .filter { $0.showsOnWorkout || usedGroupIDs.contains($0.id) }
            .sorted { $0.orderIndex < $1.orderIndex }

        return groups.map { group in
            let rows = (pendingByGroup[group.id] ?? []).sorted { $0.orderIndex < $1.orderIndex }
            let doneCount = doneByGroup[group.id]?.count ?? 0
            return WorkoutSectionModel(
                id: group.id.uuidString,
                title: group.name,
                subtitle: nil,
                mode: .muscleGroups,
                muscleGroup: group,
                rows: rows,
                doneCount: doneCount
            )
        }
    }

    private func weekdaySections() -> [WorkoutSectionModel] {
        let pendingByDay = Dictionary(grouping: pendingExercises, by: { $0.weekdayIndex ?? 1 })
        let doneByDay = Dictionary(grouping: doneExercises, by: { $0.weekdayIndex ?? 1 })

        return weekdayHeaders.map { day, label in
            let rows = (pendingByDay[day] ?? []).sorted { $0.orderIndex < $1.orderIndex }
            let doneCount = doneByDay[day]?.count ?? 0
            return WorkoutSectionModel(
                id: "weekday-\(day)",
                title: label,
                subtitle: day > 5 ? "Rest" : nil,
                mode: .weekdays,
                muscleGroup: nil,
                rows: rows,
                doneCount: doneCount
            )
        }
    }

    private func customSections() -> [WorkoutSectionModel] {
        let pendingBySlot = Dictionary(grouping: pendingExercises, by: { normalizeGroupName($0.customSlot ?? "A") })
        let doneBySlot = Dictionary(grouping: doneExercises, by: { normalizeGroupName($0.customSlot ?? "A") })

        return customSlots.map { slot in
            let key = normalizeGroupName(slot)
            let rows = (pendingBySlot[key] ?? []).sorted { $0.orderIndex < $1.orderIndex }
            let doneCount = doneBySlot[key]?.count ?? 0
            return WorkoutSectionModel(
                id: "custom-\(slot)",
                title: "Workout \(slot)",
                subtitle: nil,
                mode: .custom,
                muscleGroup: nil,
                rows: rows,
                doneCount: doneCount
            )
        }
    }

    private func parseWeekday(_ sectionID: String) -> Int? {
        guard sectionID.hasPrefix("weekday-") else { return nil }
        return Int(sectionID.replacingOccurrences(of: "weekday-", with: ""))
    }

    private func parseCustomSlot(_ sectionID: String) -> String? {
        guard sectionID.hasPrefix("custom-") else { return nil }
        return sectionID.replacingOccurrences(of: "custom-", with: "")
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
            guard let id = card.muscleGroupID,
                  let group = muscleGroups.first(where: { $0.id == id })
            else {
                return 0
            }
            let key = normalizeGroupName(group.name)
            return completionLogs
                .filter { $0.weekStartDate == activeWeekStart }
                .filter { log in
                    let groups = [log.muscleGroupName] + parseCSV(log.secondaryMuscleGroupsRaw)
                    return groups.map(normalizeGroupName).contains(key)
                }
                .compactMap(\.setsSnapshot)
                .reduce(0, +)
        case .workoutDays:
            let days = Set(
                completionLogs
                    .filter { $0.weekStartDate == activeWeekStart }
                    .map { $0.completedAt.startOfDayDate() }
            )
            return days.count
        }
    }

    private func load(for exercise: WeeklyExerciseEntity) -> Double? {
        guard let reps = exercise.reps,
              let kg = exercise.weightKg else {
            return nil
        }
        return Double(reps) * kg
    }

    private func parseCSV(_ raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizeGroupName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    private var defaultTrackingWidgetOrderRaw: String {
        [
            TrackingWidgetID.weeklySets.rawValue,
            TrackingWidgetID.workoutDays.rawValue,
            TrackingWidgetID.muscleTrend.rawValue,
            TrackingWidgetID.currentWeekByMuscle.rawValue,
            TrackingWidgetID.bodyMetrics.rawValue,
            TrackingWidgetID.classicPRs.rawValue
        ].joined(separator: ",")
    }
}
