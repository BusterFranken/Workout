import Foundation
import UniformTypeIdentifiers
import SwiftUI

// MARK: - DTOs

struct MuscleGroupDTO: Codable {
    let id: UUID
    let name: String
    let orderIndex: Int
    let showsOnWorkout: Bool
    let isArchived: Bool
    let createdAt: Date

    init(from entity: MuscleGroupEntity) {
        self.id = entity.id
        self.name = entity.name
        self.orderIndex = entity.orderIndex
        self.showsOnWorkout = entity.showsOnWorkout
        self.isArchived = entity.isArchived
        self.createdAt = entity.createdAt
    }

    func toEntity() -> MuscleGroupEntity {
        MuscleGroupEntity(
            id: id,
            name: name,
            orderIndex: orderIndex,
            showsOnWorkout: showsOnWorkout,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }
}

struct ExerciseDTO: Codable {
    let id: UUID
    let name: String
    let primaryMuscleGroupID: UUID?
    let primaryMuscleGroupName: String
    let secondaryMuscleGroupsRaw: String
    let synonymsRaw: String
    let notes: String
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    let categoryRaw: String?
    let primarySubMuscleName: String?
    let instructionStepsRaw: String?
    let instructionImagesData: Data?

    init(from entity: ExerciseEntity) {
        self.id = entity.id
        self.name = entity.name
        self.primaryMuscleGroupID = entity.primaryMuscleGroupID
        self.primaryMuscleGroupName = entity.primaryMuscleGroupName
        self.secondaryMuscleGroupsRaw = entity.secondaryMuscleGroupsRaw
        self.synonymsRaw = entity.synonymsRaw
        self.notes = entity.notes
        self.isArchived = entity.isArchived
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
        self.categoryRaw = entity.categoryRaw
        self.primarySubMuscleName = entity.primarySubMuscleName
        self.instructionStepsRaw = entity.instructionStepsRaw
        self.instructionImagesData = entity.instructionImagesData
    }

    func toEntity() -> ExerciseEntity {
        ExerciseEntity(
            id: id,
            name: name,
            primaryMuscleGroupID: primaryMuscleGroupID,
            primaryMuscleGroupName: primaryMuscleGroupName,
            secondaryMuscleGroupsRaw: secondaryMuscleGroupsRaw,
            synonymsRaw: synonymsRaw,
            notes: notes,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            categoryRaw: categoryRaw ?? "exercise",
            primarySubMuscleName: primarySubMuscleName,
            instructionStepsRaw: instructionStepsRaw ?? "",
            instructionImagesData: instructionImagesData
        )
    }
}

struct WorkoutTemplateDTO: Codable {
    let id: UUID
    let name: String
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    let emoji: String?
    let notes: String?
    let coverImageBase64: String?

    init(from entity: WorkoutTemplateEntity) {
        self.id = entity.id
        self.name = entity.name
        self.isArchived = entity.isArchived
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
        self.emoji = entity.emoji
        self.notes = entity.notes
        self.coverImageBase64 = entity.coverImageData?.base64EncodedString()
    }

    func toEntity() -> WorkoutTemplateEntity {
        WorkoutTemplateEntity(
            id: id,
            name: name,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            emoji: emoji,
            notes: notes,
            coverImageData: coverImageBase64.flatMap { Data(base64Encoded: $0) }
        )
    }
}

struct WorkoutTemplateExerciseDTO: Codable {
    let id: UUID
    let templateID: UUID
    let exerciseID: UUID?
    let name: String
    let muscleGroupID: UUID?
    let muscleGroupName: String
    let secondaryMuscleGroupsRaw: String
    let notes: String
    let weekdayIndex: Int?
    let customSlot: String?
    let orderIndex: Int
    let sets: Int?
    let reps: Int?
    let seconds: Int?
    let weightKg: Double?
    let headerID: UUID?
    let categoryRaw: String?
    let weeklyTarget: Int?
    let durationMinutes: Int?
    let intensityLabel: String?
    let inclinePercent: Double?
    let distanceKm: Double?
    let heartRateTarget: Int?
    let subMuscleName: String?
    let instructionStepsRaw: String?
    let instructionImagesData: Data?

    init(from entity: WorkoutTemplateExerciseEntity) {
        self.id = entity.id
        self.templateID = entity.templateID
        self.exerciseID = entity.exerciseID
        self.name = entity.name
        self.muscleGroupID = entity.muscleGroupID
        self.muscleGroupName = entity.muscleGroupName
        self.secondaryMuscleGroupsRaw = entity.secondaryMuscleGroupsRaw
        self.notes = entity.notes
        self.weekdayIndex = entity.weekdayIndex
        self.customSlot = entity.customSlot
        self.orderIndex = entity.orderIndex
        self.sets = entity.sets
        self.reps = entity.reps
        self.seconds = entity.seconds
        self.weightKg = entity.weightKg
        self.headerID = entity.headerID
        self.categoryRaw = entity.categoryRaw
        self.weeklyTarget = entity.weeklyTarget
        self.durationMinutes = entity.durationMinutes
        self.intensityLabel = entity.intensityLabel
        self.inclinePercent = entity.inclinePercent
        self.distanceKm = entity.distanceKm
        self.heartRateTarget = entity.heartRateTarget
        self.subMuscleName = entity.subMuscleName
        self.instructionStepsRaw = entity.instructionStepsRaw
        self.instructionImagesData = entity.instructionImagesData
    }

    func toEntity() -> WorkoutTemplateExerciseEntity {
        WorkoutTemplateExerciseEntity(
            id: id,
            templateID: templateID,
            exerciseID: exerciseID,
            name: name,
            muscleGroupID: muscleGroupID,
            muscleGroupName: muscleGroupName,
            secondaryMuscleGroupsRaw: secondaryMuscleGroupsRaw,
            notes: notes,
            weekdayIndex: weekdayIndex,
            customSlot: customSlot,
            orderIndex: orderIndex,
            sets: sets,
            reps: reps,
            seconds: seconds,
            weightKg: weightKg,
            headerID: headerID,
            categoryRaw: categoryRaw ?? "exercise",
            weeklyTarget: weeklyTarget ?? 1,
            durationMinutes: durationMinutes,
            intensityLabel: intensityLabel ?? "",
            inclinePercent: inclinePercent,
            distanceKm: distanceKm,
            heartRateTarget: heartRateTarget,
            subMuscleName: subMuscleName,
            instructionStepsRaw: instructionStepsRaw ?? "",
            instructionImagesData: instructionImagesData
        )
    }
}

struct WeeklyExerciseDTO: Codable {
    let id: UUID
    let weekStartDate: Date
    let exerciseID: UUID?
    let name: String
    let muscleGroupID: UUID?
    let muscleGroupName: String
    let secondaryMuscleGroupsRaw: String
    let notes: String
    let weekdayIndex: Int?
    let customSlot: String?
    let orderIndex: Int
    let sets: Int?
    let reps: Int?
    let seconds: Int?
    let weightKg: Double?
    let completedAt: Date?
    let removedAt: Date?
    let headerID: UUID?
    let categoryRaw: String?
    let weeklyTarget: Int?
    let durationMinutes: Int?
    let intensityLabel: String?
    let inclinePercent: Double?
    let distanceKm: Double?
    let heartRateTarget: Int?
    let subMuscleName: String?
    let instructionStepsRaw: String?
    let instructionImagesData: Data?

    init(from entity: WeeklyExerciseEntity) {
        self.id = entity.id
        self.weekStartDate = entity.weekStartDate
        self.exerciseID = entity.exerciseID
        self.name = entity.name
        self.muscleGroupID = entity.muscleGroupID
        self.muscleGroupName = entity.muscleGroupName
        self.secondaryMuscleGroupsRaw = entity.secondaryMuscleGroupsRaw
        self.notes = entity.notes
        self.weekdayIndex = entity.weekdayIndex
        self.customSlot = entity.customSlot
        self.orderIndex = entity.orderIndex
        self.sets = entity.sets
        self.reps = entity.reps
        self.seconds = entity.seconds
        self.weightKg = entity.weightKg
        self.completedAt = entity.completedAt
        self.removedAt = entity.removedAt
        self.headerID = entity.headerID
        self.categoryRaw = entity.categoryRaw
        self.weeklyTarget = entity.weeklyTarget
        self.durationMinutes = entity.durationMinutes
        self.intensityLabel = entity.intensityLabel
        self.inclinePercent = entity.inclinePercent
        self.distanceKm = entity.distanceKm
        self.heartRateTarget = entity.heartRateTarget
        self.subMuscleName = entity.subMuscleName
        self.instructionStepsRaw = entity.instructionStepsRaw
        self.instructionImagesData = entity.instructionImagesData
    }

    func toEntity() -> WeeklyExerciseEntity {
        WeeklyExerciseEntity(
            id: id,
            weekStartDate: weekStartDate,
            exerciseID: exerciseID,
            name: name,
            muscleGroupID: muscleGroupID,
            muscleGroupName: muscleGroupName,
            secondaryMuscleGroupsRaw: secondaryMuscleGroupsRaw,
            notes: notes,
            weekdayIndex: weekdayIndex,
            customSlot: customSlot,
            orderIndex: orderIndex,
            sets: sets,
            reps: reps,
            seconds: seconds,
            weightKg: weightKg,
            completedAt: completedAt,
            removedAt: removedAt,
            headerID: headerID,
            categoryRaw: categoryRaw ?? "exercise",
            weeklyTarget: weeklyTarget ?? 1,
            durationMinutes: durationMinutes,
            intensityLabel: intensityLabel ?? "",
            inclinePercent: inclinePercent,
            distanceKm: distanceKm,
            heartRateTarget: heartRateTarget,
            subMuscleName: subMuscleName,
            instructionStepsRaw: instructionStepsRaw ?? "",
            instructionImagesData: instructionImagesData
        )
    }
}

struct CompletionLogDTO: Codable {
    let id: UUID
    let weekStartDate: Date
    let weeklyExerciseID: UUID
    let exerciseID: UUID?
    let nameSnapshot: String
    let muscleGroupID: UUID?
    let muscleGroupName: String
    let secondaryMuscleGroupsRaw: String
    let completedAt: Date
    let setsSnapshot: Int?
    let repsSnapshot: Int?
    let secondsSnapshot: Int?
    let weightKgSnapshot: Double?
    let loadSnapshot: Double?
    let isSimulated: Bool
    let categoryRaw: String?
    let durationMinutesSnapshot: Int?
    let intensityLabelSnapshot: String?
    let inclinePercentSnapshot: Double?
    let distanceKmSnapshot: Double?
    let heartRateTargetSnapshot: Int?
    let subMuscleNameSnapshot: String?

    init(from entity: CompletionLogEntity) {
        self.id = entity.id
        self.weekStartDate = entity.weekStartDate
        self.weeklyExerciseID = entity.weeklyExerciseID
        self.exerciseID = entity.exerciseID
        self.nameSnapshot = entity.nameSnapshot
        self.muscleGroupID = entity.muscleGroupID
        self.muscleGroupName = entity.muscleGroupName
        self.secondaryMuscleGroupsRaw = entity.secondaryMuscleGroupsRaw
        self.completedAt = entity.completedAt
        self.setsSnapshot = entity.setsSnapshot
        self.repsSnapshot = entity.repsSnapshot
        self.secondsSnapshot = entity.secondsSnapshot
        self.weightKgSnapshot = entity.weightKgSnapshot
        self.loadSnapshot = entity.loadSnapshot
        self.isSimulated = entity.isSimulated
        self.categoryRaw = entity.categoryRaw
        self.durationMinutesSnapshot = entity.durationMinutesSnapshot
        self.intensityLabelSnapshot = entity.intensityLabelSnapshot
        self.inclinePercentSnapshot = entity.inclinePercentSnapshot
        self.distanceKmSnapshot = entity.distanceKmSnapshot
        self.heartRateTargetSnapshot = entity.heartRateTargetSnapshot
        self.subMuscleNameSnapshot = entity.subMuscleNameSnapshot
    }

    func toEntity() -> CompletionLogEntity {
        CompletionLogEntity(
            id: id,
            weekStartDate: weekStartDate,
            weeklyExerciseID: weeklyExerciseID,
            exerciseID: exerciseID,
            nameSnapshot: nameSnapshot,
            muscleGroupID: muscleGroupID,
            muscleGroupName: muscleGroupName,
            secondaryMuscleGroupsRaw: secondaryMuscleGroupsRaw,
            completedAt: completedAt,
            setsSnapshot: setsSnapshot,
            repsSnapshot: repsSnapshot,
            secondsSnapshot: secondsSnapshot,
            weightKgSnapshot: weightKgSnapshot,
            loadSnapshot: loadSnapshot,
            isSimulated: isSimulated,
            categoryRaw: categoryRaw ?? "exercise",
            durationMinutesSnapshot: durationMinutesSnapshot,
            intensityLabelSnapshot: intensityLabelSnapshot ?? "",
            inclinePercentSnapshot: inclinePercentSnapshot,
            distanceKmSnapshot: distanceKmSnapshot,
            heartRateTargetSnapshot: heartRateTargetSnapshot,
            subMuscleNameSnapshot: subMuscleNameSnapshot
        )
    }
}

struct GoalCardDTO: Codable {
    let id: UUID
    let title: String
    let metricTypeRaw: String
    let targetValue: Int
    let orderIndex: Int
    let muscleGroupID: UUID?
    let isSystem: Bool
    let isArchived: Bool
    let subMuscleName: String?

    init(from entity: GoalCardEntity) {
        self.id = entity.id
        self.title = entity.title
        self.metricTypeRaw = entity.metricTypeRaw
        self.targetValue = entity.targetValue
        self.orderIndex = entity.orderIndex
        self.muscleGroupID = entity.muscleGroupID
        self.isSystem = entity.isSystem
        self.isArchived = entity.isArchived
        self.subMuscleName = entity.subMuscleName
    }

    func toEntity() -> GoalCardEntity {
        GoalCardEntity(
            id: id,
            title: title,
            metricTypeRaw: metricTypeRaw,
            targetValue: targetValue,
            orderIndex: orderIndex,
            muscleGroupID: muscleGroupID,
            isSystem: isSystem,
            isArchived: isArchived,
            subMuscleName: subMuscleName
        )
    }
}

struct BodyMetricEntryDTO: Codable {
    let id: UUID
    let kindRaw: String
    let value: Double
    let recordedAt: Date

    init(from entity: BodyMetricEntryEntity) {
        self.id = entity.id
        self.kindRaw = entity.kindRaw
        self.value = entity.value
        self.recordedAt = entity.recordedAt
    }

    func toEntity() -> BodyMetricEntryEntity {
        BodyMetricEntryEntity(
            id: id,
            kindRaw: kindRaw,
            value: value,
            recordedAt: recordedAt
        )
    }
}

struct PRRecordDTO: Codable {
    let id: UUID
    let exerciseLabel: String
    let value: Double
    let recordedAt: Date
    let notes: String

    init(from entity: PRRecordEntity) {
        self.id = entity.id
        self.exerciseLabel = entity.exerciseLabel
        self.value = entity.value
        self.recordedAt = entity.recordedAt
        self.notes = entity.notes
    }

    func toEntity() -> PRRecordEntity {
        PRRecordEntity(
            id: id,
            exerciseLabel: exerciseLabel,
            value: value,
            recordedAt: recordedAt,
            notes: notes
        )
    }
}

struct SectionHeaderDTO: Codable {
    let id: UUID
    let title: String
    let orderIndex: Int
    let weekStartDate: Date?
    let templateID: UUID?
    let createdAt: Date
    let weeklyGoal: Int?

    init(from entity: SectionHeaderEntity) {
        self.id = entity.id
        self.title = entity.title
        self.orderIndex = entity.orderIndex
        self.weekStartDate = entity.weekStartDate
        self.templateID = entity.templateID
        self.createdAt = entity.createdAt
        self.weeklyGoal = entity.weeklyGoal
    }

    func toEntity() -> SectionHeaderEntity {
        SectionHeaderEntity(
            id: id,
            title: title,
            orderIndex: orderIndex,
            weekStartDate: weekStartDate,
            templateID: templateID,
            createdAt: createdAt,
            weeklyGoal: weeklyGoal
        )
    }
}

struct AppSettingsDTO: Codable {
    let id: UUID
    let activeWeekStartDate: Date
    let activeWorkoutName: String
    let workoutViewModeRaw: String
    let weeklySetTarget: Int
    let unitSystemRaw: String
    let themePreferenceRaw: String
    let trackingWidgetOrderRaw: String
    let seedVersion: Int

    init(from entity: AppSettingsEntity) {
        self.id = entity.id
        self.activeWeekStartDate = entity.activeWeekStartDate
        self.activeWorkoutName = entity.activeWorkoutName
        self.workoutViewModeRaw = entity.workoutViewModeRaw
        self.weeklySetTarget = entity.weeklySetTarget
        self.unitSystemRaw = entity.unitSystemRaw
        self.themePreferenceRaw = entity.themePreferenceRaw
        self.trackingWidgetOrderRaw = entity.trackingWidgetOrderRaw
        self.seedVersion = entity.seedVersion
    }

    func toEntity() -> AppSettingsEntity {
        AppSettingsEntity(
            id: id,
            activeWeekStartDate: activeWeekStartDate,
            activeWorkoutName: activeWorkoutName,
            workoutViewModeRaw: workoutViewModeRaw,
            weeklySetTarget: weeklySetTarget,
            unitSystemRaw: unitSystemRaw,
            themePreferenceRaw: themePreferenceRaw,
            trackingWidgetOrderRaw: trackingWidgetOrderRaw,
            seedVersion: seedVersion
        )
    }
}

// MARK: - Top-level export container

struct WorkoutDataExport: Codable {
    let exportVersion: Int
    let exportedAt: Date
    let appVersion: String
    let muscleGroups: [MuscleGroupDTO]
    let exercises: [ExerciseDTO]
    let workoutTemplates: [WorkoutTemplateDTO]
    let workoutTemplateExercises: [WorkoutTemplateExerciseDTO]
    let weeklyExercises: [WeeklyExerciseDTO]
    let completionLogs: [CompletionLogDTO]
    let goalCards: [GoalCardDTO]
    let bodyMetricEntries: [BodyMetricEntryDTO]
    let prRecords: [PRRecordDTO]
    let sectionHeaders: [SectionHeaderDTO]
    let appSettings: AppSettingsDTO?
    let themeAccentOptionRaw: String?
    let customAccentRed: Double?
    let customAccentGreen: Double?
    let customAccentBlue: Double?
    let customAccentAlpha: Double?
}

// MARK: - FileDocument wrapper

struct DataExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Import error

enum DataImportError: LocalizedError {
    case invalidFormat(String)
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail):
            return "Invalid file format: \(detail)"
        case .unsupportedVersion(let version):
            return "Unsupported export version \(version). Please update the app."
        }
    }
}
