import Foundation
import SwiftData

enum GoalMetricType: String, Codable, CaseIterable, Identifiable {
    case totalSets
    case exercisesDone
    case muscleGroupSets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .totalSets:
            return "Sets"
        case .exercisesDone:
            return "Exercises"
        case .muscleGroupSets:
            return "Muscle Sets"
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
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroupID: UUID?,
        primaryMuscleGroupName: String,
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleGroupID = primaryMuscleGroupID
        self.primaryMuscleGroupName = primaryMuscleGroupName
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
    var orderIndex: Int
    var sets: Int?
    var reps: Int?
    var seconds: Int?
    var weightKg: Double?
    var weightCount: Int?

    init(
        id: UUID = UUID(),
        templateID: UUID,
        exerciseID: UUID?,
        name: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        orderIndex: Int,
        sets: Int?,
        reps: Int?,
        seconds: Int?,
        weightKg: Double?,
        weightCount: Int?
    ) {
        self.id = id
        self.templateID = templateID
        self.exerciseID = exerciseID
        self.name = name
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.orderIndex = orderIndex
        self.sets = sets
        self.reps = reps
        self.seconds = seconds
        self.weightKg = weightKg
        self.weightCount = weightCount
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
    var orderIndex: Int
    var sets: Int?
    var reps: Int?
    var seconds: Int?
    var weightKg: Double?
    var weightCount: Int?
    var completedAt: Date?
    var removedAt: Date?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        exerciseID: UUID?,
        name: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        orderIndex: Int,
        sets: Int?,
        reps: Int?,
        seconds: Int?,
        weightKg: Double?,
        weightCount: Int?,
        completedAt: Date? = nil,
        removedAt: Date? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.exerciseID = exerciseID
        self.name = name
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.orderIndex = orderIndex
        self.sets = sets
        self.reps = reps
        self.seconds = seconds
        self.weightKg = weightKg
        self.weightCount = weightCount
        self.completedAt = completedAt
        self.removedAt = removedAt
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
    var completedAt: Date
    var setsSnapshot: Int?
    var repsSnapshot: Int?
    var secondsSnapshot: Int?
    var weightKgSnapshot: Double?
    var weightCountSnapshot: Int?
    var loadSnapshot: Double?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weeklyExerciseID: UUID,
        exerciseID: UUID?,
        nameSnapshot: String,
        muscleGroupID: UUID?,
        muscleGroupName: String,
        completedAt: Date,
        setsSnapshot: Int?,
        repsSnapshot: Int?,
        secondsSnapshot: Int?,
        weightKgSnapshot: Double?,
        weightCountSnapshot: Int?,
        loadSnapshot: Double?
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weeklyExerciseID = weeklyExerciseID
        self.exerciseID = exerciseID
        self.nameSnapshot = nameSnapshot
        self.muscleGroupID = muscleGroupID
        self.muscleGroupName = muscleGroupName
        self.completedAt = completedAt
        self.setsSnapshot = setsSnapshot
        self.repsSnapshot = repsSnapshot
        self.secondsSnapshot = secondsSnapshot
        self.weightKgSnapshot = weightKgSnapshot
        self.weightCountSnapshot = weightCountSnapshot
        self.loadSnapshot = loadSnapshot
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

    init(
        id: UUID = UUID(),
        title: String,
        metricTypeRaw: String,
        targetValue: Int,
        orderIndex: Int,
        muscleGroupID: UUID?,
        isSystem: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.metricTypeRaw = metricTypeRaw
        self.targetValue = targetValue
        self.orderIndex = orderIndex
        self.muscleGroupID = muscleGroupID
        self.isSystem = isSystem
        self.isArchived = isArchived
    }

    var metricType: GoalMetricType {
        GoalMetricType(rawValue: metricTypeRaw) ?? .totalSets
    }
}

@Model
final class AppSettingsEntity {
    @Attribute(.unique) var id: UUID
    var activeWeekStartDate: Date
    var weeklySetTarget: Int
    var seedVersion: Int

    init(
        id: UUID = UUID(),
        activeWeekStartDate: Date,
        weeklySetTarget: Int,
        seedVersion: Int
    ) {
        self.id = id
        self.activeWeekStartDate = activeWeekStartDate
        self.weeklySetTarget = weeklySetTarget
        self.seedVersion = seedVersion
    }
}
