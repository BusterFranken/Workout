// ⚠️ IMPORTANT: These models are persisted to disk via SwiftData.
// If you modify any stored properties (add, remove, rename, or change type),
// you MUST create a new schema version in SchemaVersions.swift first.
// See that file for step-by-step instructions.

import Foundation
import SwiftData

enum ExerciseCategory: String, Codable, CaseIterable {
    case exercise = "exercise"
    case stretch = "stretch"
    case cardio = "cardio"
}

enum GoalMetricType: String, Codable, CaseIterable, Identifiable {
    case totalSets
    case exercisesDone
    case muscleGroupSets
    case workoutDays
    case muscleGroupExercises
    case totalVolume
    case muscleGroupVolume
    case totalReps
    case muscleGroupReps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .totalSets:
            return "Sets"
        case .exercisesDone:
            return "Exercises"
        case .muscleGroupSets:
            return "Muscle Sets"
        case .workoutDays:
            return "Workout Days"
        case .muscleGroupExercises:
            return "Muscle Exercises"
        case .totalVolume:
            return "Volume Load"
        case .muscleGroupVolume:
            return "Muscle Volume"
        case .totalReps:
            return "Reps"
        case .muscleGroupReps:
            return "Muscle Reps"
        }
    }
}

enum WorkoutViewMode: String, Codable, CaseIterable, Identifiable {
    case muscleGroups
    case weekdays
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muscleGroups:
            return "Muscle Groups"
        case .weekdays:
            return "Weekdays"
        case .custom:
            return "Custom"
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kg:
            return "kg"
        case .lb:
            return "lb"
        }
    }
}

enum AppThemePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

enum BodyMetricKind: String, Codable, CaseIterable, Identifiable {
    case scaleWeight
    case visualBodyFat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scaleWeight:
            return "Scale Weight"
        case .visualBodyFat:
            return "Visual Body Fat"
        }
    }
}

@Model
final class MuscleGroupEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var orderIndex: Int
    var showsOnWorkout: Bool
    var isArchived: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        orderIndex: Int,
        showsOnWorkout: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.showsOnWorkout = showsOnWorkout
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}

@Model
final class ExerciseEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleGroupID: UUID?
    var primaryMuscleGroupName: String
    var secondaryMuscleGroupsRaw: String
    var synonymsRaw: String
    var notes: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var categoryRaw: String
    var primarySubMuscleName: String?

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroupID: UUID?,
        primaryMuscleGroupName: String,
        secondaryMuscleGroupsRaw: String = "",
        synonymsRaw: String = "",
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        categoryRaw: String = "exercise",
        primarySubMuscleName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleGroupID = primaryMuscleGroupID
        self.primaryMuscleGroupName = primaryMuscleGroupName
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw
        self.synonymsRaw = synonymsRaw
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryRaw = categoryRaw
        self.primarySubMuscleName = primarySubMuscleName
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .exercise }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class WorkoutTemplateEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class WorkoutTemplateExerciseEntity {
    @Attribute(.unique) var id: UUID
    var templateID: UUID
    var exerciseID: UUID?
    var name: String
    var muscleGroupID: UUID?
    var muscleGroupName: String
    var secondaryMuscleGroupsRaw: String
    var notes: String
    var weekdayIndex: Int?
    var customSlot: String?
    var orderIndex: Int
    var sets: Int?
    var reps: Int?
    var seconds: Int?
    var weightKg: Double?
    var headerID: UUID?
    var categoryRaw: String
    var weeklyTarget: Int
    var durationMinutes: Int?
    var intensityLabel: String
    var inclinePercent: Double?
    var distanceKm: Double?
    var heartRateTarget: Int?
    var subMuscleName: String?

    init(
        id: UUID = UUID(),
        templateID: UUID,
        exerciseID: UUID?,
        name: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        secondaryMuscleGroupsRaw: String = "",
        notes: String = "",
        weekdayIndex: Int? = nil,
        customSlot: String? = nil,
        orderIndex: Int,
        sets: Int?,
        reps: Int?,
        seconds: Int?,
        weightKg: Double?,
        headerID: UUID? = nil,
        categoryRaw: String = "exercise",
        weeklyTarget: Int = 1,
        durationMinutes: Int? = nil,
        intensityLabel: String = "",
        inclinePercent: Double? = nil,
        distanceKm: Double? = nil,
        heartRateTarget: Int? = nil,
        subMuscleName: String? = nil
    ) {
        self.id = id
        self.templateID = templateID
        self.exerciseID = exerciseID
        self.name = name
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw
        self.notes = notes
        self.weekdayIndex = weekdayIndex
        self.customSlot = customSlot
        self.orderIndex = orderIndex
        self.sets = sets
        self.reps = reps
        self.seconds = seconds
        self.weightKg = weightKg
        self.headerID = headerID
        self.categoryRaw = categoryRaw
        self.weeklyTarget = weeklyTarget
        self.durationMinutes = durationMinutes
        self.intensityLabel = intensityLabel
        self.inclinePercent = inclinePercent
        self.distanceKm = distanceKm
        self.heartRateTarget = heartRateTarget
        self.subMuscleName = subMuscleName
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .exercise }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class WeeklyExerciseEntity {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var exerciseID: UUID?
    var name: String
    var muscleGroupID: UUID?
    var muscleGroupName: String
    var secondaryMuscleGroupsRaw: String
    var notes: String
    var weekdayIndex: Int?
    var customSlot: String?
    var orderIndex: Int
    var sets: Int?
    var reps: Int?
    var seconds: Int?
    var weightKg: Double?
    var completedAt: Date?
    var removedAt: Date?
    var headerID: UUID?
    var categoryRaw: String
    var weeklyTarget: Int
    var durationMinutes: Int?
    var intensityLabel: String
    var inclinePercent: Double?
    var distanceKm: Double?
    var heartRateTarget: Int?
    var subMuscleName: String?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        exerciseID: UUID?,
        name: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        secondaryMuscleGroupsRaw: String = "",
        notes: String = "",
        weekdayIndex: Int? = nil,
        customSlot: String? = nil,
        orderIndex: Int,
        sets: Int?,
        reps: Int?,
        seconds: Int?,
        weightKg: Double?,
        completedAt: Date? = nil,
        removedAt: Date? = nil,
        headerID: UUID? = nil,
        categoryRaw: String = "exercise",
        weeklyTarget: Int = 1,
        durationMinutes: Int? = nil,
        intensityLabel: String = "",
        inclinePercent: Double? = nil,
        distanceKm: Double? = nil,
        heartRateTarget: Int? = nil,
        subMuscleName: String? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.exerciseID = exerciseID
        self.name = name
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw
        self.notes = notes
        self.weekdayIndex = weekdayIndex
        self.customSlot = customSlot
        self.orderIndex = orderIndex
        self.sets = sets
        self.reps = reps
        self.seconds = seconds
        self.weightKg = weightKg
        self.completedAt = completedAt
        self.removedAt = removedAt
        self.headerID = headerID
        self.categoryRaw = categoryRaw
        self.weeklyTarget = weeklyTarget
        self.durationMinutes = durationMinutes
        self.intensityLabel = intensityLabel
        self.inclinePercent = inclinePercent
        self.distanceKm = distanceKm
        self.heartRateTarget = heartRateTarget
        self.subMuscleName = subMuscleName
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .exercise }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class CompletionLogEntity {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var weeklyExerciseID: UUID
    var exerciseID: UUID?
    var nameSnapshot: String
    var muscleGroupID: UUID?
    var muscleGroupName: String
    var secondaryMuscleGroupsRaw: String
    var completedAt: Date
    var setsSnapshot: Int?
    var repsSnapshot: Int?
    var secondsSnapshot: Int?
    var weightKgSnapshot: Double?
    var loadSnapshot: Double?
    var isSimulated: Bool
    var categoryRaw: String
    var durationMinutesSnapshot: Int?
    var intensityLabelSnapshot: String
    var inclinePercentSnapshot: Double?
    var distanceKmSnapshot: Double?
    var heartRateTargetSnapshot: Int?
    var subMuscleNameSnapshot: String?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weeklyExerciseID: UUID,
        exerciseID: UUID?,
        nameSnapshot: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        secondaryMuscleGroupsRaw: String = "",
        completedAt: Date,
        setsSnapshot: Int?,
        repsSnapshot: Int?,
        secondsSnapshot: Int?,
        weightKgSnapshot: Double?,
        loadSnapshot: Double?,
        isSimulated: Bool = false,
        categoryRaw: String = "exercise",
        durationMinutesSnapshot: Int? = nil,
        intensityLabelSnapshot: String = "",
        inclinePercentSnapshot: Double? = nil,
        distanceKmSnapshot: Double? = nil,
        heartRateTargetSnapshot: Int? = nil,
        subMuscleNameSnapshot: String? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weeklyExerciseID = weeklyExerciseID
        self.exerciseID = exerciseID
        self.nameSnapshot = nameSnapshot
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw
        self.completedAt = completedAt
        self.setsSnapshot = setsSnapshot
        self.repsSnapshot = repsSnapshot
        self.secondsSnapshot = secondsSnapshot
        self.weightKgSnapshot = weightKgSnapshot
        self.loadSnapshot = loadSnapshot
        self.isSimulated = isSimulated
        self.categoryRaw = categoryRaw
        self.durationMinutesSnapshot = durationMinutesSnapshot
        self.intensityLabelSnapshot = intensityLabelSnapshot
        self.inclinePercentSnapshot = inclinePercentSnapshot
        self.distanceKmSnapshot = distanceKmSnapshot
        self.heartRateTargetSnapshot = heartRateTargetSnapshot
        self.subMuscleNameSnapshot = subMuscleNameSnapshot
    }

    var category: ExerciseCategory {
        ExerciseCategory(rawValue: categoryRaw) ?? .exercise
    }
}

@Model
final class GoalCardEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var metricTypeRaw: String
    var targetValue: Int
    var orderIndex: Int
    var muscleGroupID: UUID?
    var isSystem: Bool
    var isArchived: Bool
    var subMuscleName: String?

    init(
        id: UUID = UUID(),
        title: String,
        metricTypeRaw: String,
        targetValue: Int,
        orderIndex: Int,
        muscleGroupID: UUID?,
        isSystem: Bool = false,
        isArchived: Bool = false,
        subMuscleName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.metricTypeRaw = metricTypeRaw
        self.targetValue = targetValue
        self.orderIndex = orderIndex
        self.muscleGroupID = muscleGroupID
        self.isSystem = isSystem
        self.isArchived = isArchived
        self.subMuscleName = subMuscleName
    }

    var metricType: GoalMetricType {
        GoalMetricType(rawValue: metricTypeRaw) ?? .totalSets
    }
}

@Model
final class BodyMetricEntryEntity {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var value: Double
    var recordedAt: Date

    init(
        id: UUID = UUID(),
        kindRaw: String,
        value: Double,
        recordedAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.value = value
        self.recordedAt = recordedAt
    }

    var kind: BodyMetricKind {
        BodyMetricKind(rawValue: kindRaw) ?? .scaleWeight
    }
}

@Model
final class PRRecordEntity {
    @Attribute(.unique) var id: UUID
    var exerciseLabel: String
    var value: Double
    var recordedAt: Date
    var notes: String

    init(
        id: UUID = UUID(),
        exerciseLabel: String,
        value: Double,
        recordedAt: Date = .now,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseLabel = exerciseLabel
        self.value = value
        self.recordedAt = recordedAt
        self.notes = notes
    }
}

@Model
final class SectionHeaderEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var orderIndex: Int
    var weekStartDate: Date?
    var templateID: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        orderIndex: Int,
        weekStartDate: Date? = nil,
        templateID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.weekStartDate = weekStartDate
        self.templateID = templateID
        self.createdAt = createdAt
    }
}

@Model
final class AppSettingsEntity {
    @Attribute(.unique) var id: UUID
    var activeWeekStartDate: Date
    var activeWorkoutName: String
    var workoutViewModeRaw: String
    var weeklySetTarget: Int
    var unitSystemRaw: String
    var themePreferenceRaw: String
    var trackingWidgetOrderRaw: String
    var seedVersion: Int

    init(
        id: UUID = UUID(),
        activeWeekStartDate: Date,
        activeWorkoutName: String,
        workoutViewModeRaw: String,
        weeklySetTarget: Int,
        unitSystemRaw: String,
        themePreferenceRaw: String,
        trackingWidgetOrderRaw: String,
        seedVersion: Int
    ) {
        self.id = id
        self.activeWeekStartDate = activeWeekStartDate
        self.activeWorkoutName = activeWorkoutName
        self.workoutViewModeRaw = workoutViewModeRaw
        self.weeklySetTarget = weeklySetTarget
        self.unitSystemRaw = unitSystemRaw
        self.themePreferenceRaw = themePreferenceRaw
        self.trackingWidgetOrderRaw = trackingWidgetOrderRaw
        self.seedVersion = seedVersion
    }

    var workoutViewMode: WorkoutViewMode {
        get { WorkoutViewMode(rawValue: workoutViewModeRaw) ?? .muscleGroups }
        set { workoutViewModeRaw = newValue.rawValue }
    }

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .kg }
        set { unitSystemRaw = newValue.rawValue }
    }

    var themePreference: AppThemePreference {
        get { AppThemePreference(rawValue: themePreferenceRaw) ?? .system }
        set { themePreferenceRaw = newValue.rawValue }
    }
}
