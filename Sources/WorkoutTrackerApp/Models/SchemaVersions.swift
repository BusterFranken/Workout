import Foundation
import SwiftData

// ╔══════════════════════════════════════════════════════════════╗
// ║  SCHEMA VERSIONING — READ BEFORE MODIFYING DATABASE MODELS  ║
// ╚══════════════════════════════════════════════════════════════╝
//
// The @Model entities in PersistedModels.swift are persisted to disk via SwiftData.
// If you change a model's stored properties (add, remove, rename, change type),
// you MUST create a new schema version so existing user data migrates correctly.
//
// HOW TO ADD A NEW SCHEMA VERSION:
// 1. Create a new enum (e.g. SchemaV2) conforming to VersionedSchema
//    — Copy ALL current @Model classes from PersistedModels.swift into it as-is
//    — This is the SNAPSHOT of the schema BEFORE your changes
// 2. Make your changes to the live entities in PersistedModels.swift
// 3. Add a migration stage to WorkoutMigrationPlan:
//    — Use .lightweight for simple changes (adding optional properties, etc.)
//    — Use .custom for complex changes (renaming, data transforms, etc.)
// 4. Add the new version to WorkoutMigrationPlan.schemas
// 5. Test: install the OLD version, add data, then build the NEW version
//    — verify all data is preserved
//
// SAFE CHANGES (no migration needed):
// — Adding computed properties (no storage)
// — Changing init defaults
// — Adding new methods to entities
//
// CHANGES THAT NEED A NEW VERSION:
// — Adding/removing stored properties
// — Changing a property's type
// — Renaming a stored property

// MARK: - V1 Baseline (frozen snapshot — do not edit)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            MuscleGroupEntity.self,
            ExerciseEntity.self,
            WorkoutTemplateEntity.self,
            WorkoutTemplateExerciseEntity.self,
            WeeklyExerciseEntity.self,
            CompletionLogEntity.self,
            GoalCardEntity.self,
            BodyMetricEntryEntity.self,
            PRRecordEntity.self,
            AppSettingsEntity.self,
            SectionHeaderEntity.self
        ]
    }

    @Model final class MuscleGroupEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var orderIndex: Int
        var showsOnWorkout: Bool
        var isArchived: Bool
        var createdAt: Date
        init(id: UUID = UUID(), name: String = "", orderIndex: Int = 0, showsOnWorkout: Bool = false, isArchived: Bool = false, createdAt: Date = .now) {
            self.id = id; self.name = name; self.orderIndex = orderIndex; self.showsOnWorkout = showsOnWorkout; self.isArchived = isArchived; self.createdAt = createdAt
        }
    }

    @Model final class ExerciseEntity {
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
        init(id: UUID = UUID(), name: String = "", primaryMuscleGroupID: UUID? = nil, primaryMuscleGroupName: String = "", secondaryMuscleGroupsRaw: String = "", synonymsRaw: String = "", notes: String = "", isArchived: Bool = false, createdAt: Date = .now, updatedAt: Date = .now) {
            self.id = id; self.name = name; self.primaryMuscleGroupID = primaryMuscleGroupID; self.primaryMuscleGroupName = primaryMuscleGroupName; self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw; self.synonymsRaw = synonymsRaw; self.notes = notes; self.isArchived = isArchived; self.createdAt = createdAt; self.updatedAt = updatedAt
        }
    }

    @Model final class WorkoutTemplateEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var isArchived: Bool
        var createdAt: Date
        var updatedAt: Date
        init(id: UUID = UUID(), name: String = "", isArchived: Bool = false, createdAt: Date = .now, updatedAt: Date = .now) {
            self.id = id; self.name = name; self.isArchived = isArchived; self.createdAt = createdAt; self.updatedAt = updatedAt
        }
    }

    @Model final class WorkoutTemplateExerciseEntity {
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
        init(id: UUID = UUID(), templateID: UUID = UUID(), exerciseID: UUID? = nil, name: String = "", muscleGroupID: UUID? = nil, muscleGroupName: String = "", secondaryMuscleGroupsRaw: String = "", notes: String = "", weekdayIndex: Int? = nil, customSlot: String? = nil, orderIndex: Int = 0, sets: Int? = nil, reps: Int? = nil, seconds: Int? = nil, weightKg: Double? = nil, headerID: UUID? = nil) {
            self.id = id; self.templateID = templateID; self.exerciseID = exerciseID; self.name = name; self.muscleGroupID = muscleGroupID; self.muscleGroupName = muscleGroupName; self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw; self.notes = notes; self.weekdayIndex = weekdayIndex; self.customSlot = customSlot; self.orderIndex = orderIndex; self.sets = sets; self.reps = reps; self.seconds = seconds; self.weightKg = weightKg; self.headerID = headerID
        }
    }

    @Model final class WeeklyExerciseEntity {
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
        init(id: UUID = UUID(), weekStartDate: Date = .now, exerciseID: UUID? = nil, name: String = "", muscleGroupID: UUID? = nil, muscleGroupName: String = "", secondaryMuscleGroupsRaw: String = "", notes: String = "", weekdayIndex: Int? = nil, customSlot: String? = nil, orderIndex: Int = 0, sets: Int? = nil, reps: Int? = nil, seconds: Int? = nil, weightKg: Double? = nil, completedAt: Date? = nil, removedAt: Date? = nil, headerID: UUID? = nil) {
            self.id = id; self.weekStartDate = weekStartDate; self.exerciseID = exerciseID; self.name = name; self.muscleGroupID = muscleGroupID; self.muscleGroupName = muscleGroupName; self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw; self.notes = notes; self.weekdayIndex = weekdayIndex; self.customSlot = customSlot; self.orderIndex = orderIndex; self.sets = sets; self.reps = reps; self.seconds = seconds; self.weightKg = weightKg; self.completedAt = completedAt; self.removedAt = removedAt; self.headerID = headerID
        }
    }

    @Model final class CompletionLogEntity {
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
        init(id: UUID = UUID(), weekStartDate: Date = .now, weeklyExerciseID: UUID = UUID(), exerciseID: UUID? = nil, nameSnapshot: String = "", muscleGroupID: UUID? = nil, muscleGroupName: String = "", secondaryMuscleGroupsRaw: String = "", completedAt: Date = .now, setsSnapshot: Int? = nil, repsSnapshot: Int? = nil, secondsSnapshot: Int? = nil, weightKgSnapshot: Double? = nil, loadSnapshot: Double? = nil, isSimulated: Bool = false) {
            self.id = id; self.weekStartDate = weekStartDate; self.weeklyExerciseID = weeklyExerciseID; self.exerciseID = exerciseID; self.nameSnapshot = nameSnapshot; self.muscleGroupID = muscleGroupID; self.muscleGroupName = muscleGroupName; self.secondaryMuscleGroupsRaw = secondaryMuscleGroupsRaw; self.completedAt = completedAt; self.setsSnapshot = setsSnapshot; self.repsSnapshot = repsSnapshot; self.secondsSnapshot = secondsSnapshot; self.weightKgSnapshot = weightKgSnapshot; self.loadSnapshot = loadSnapshot; self.isSimulated = isSimulated
        }
    }

    @Model final class GoalCardEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        var metricTypeRaw: String
        var targetValue: Int
        var orderIndex: Int
        var muscleGroupID: UUID?
        var isSystem: Bool
        var isArchived: Bool
        init(id: UUID = UUID(), title: String = "", metricTypeRaw: String = "", targetValue: Int = 0, orderIndex: Int = 0, muscleGroupID: UUID? = nil, isSystem: Bool = false, isArchived: Bool = false) {
            self.id = id; self.title = title; self.metricTypeRaw = metricTypeRaw; self.targetValue = targetValue; self.orderIndex = orderIndex; self.muscleGroupID = muscleGroupID; self.isSystem = isSystem; self.isArchived = isArchived
        }
    }

    @Model final class BodyMetricEntryEntity {
        @Attribute(.unique) var id: UUID
        var kindRaw: String
        var value: Double
        var recordedAt: Date
        init(id: UUID = UUID(), kindRaw: String = "", value: Double = 0, recordedAt: Date = .now) {
            self.id = id; self.kindRaw = kindRaw; self.value = value; self.recordedAt = recordedAt
        }
    }

    @Model final class PRRecordEntity {
        @Attribute(.unique) var id: UUID
        var exerciseLabel: String
        var value: Double
        var recordedAt: Date
        var notes: String
        init(id: UUID = UUID(), exerciseLabel: String = "", value: Double = 0, recordedAt: Date = .now, notes: String = "") {
            self.id = id; self.exerciseLabel = exerciseLabel; self.value = value; self.recordedAt = recordedAt; self.notes = notes
        }
    }

    @Model final class SectionHeaderEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        var orderIndex: Int
        var weekStartDate: Date?
        var templateID: UUID?
        var createdAt: Date
        init(id: UUID = UUID(), title: String = "", orderIndex: Int = 0, weekStartDate: Date? = nil, templateID: UUID? = nil, createdAt: Date = .now) {
            self.id = id; self.title = title; self.orderIndex = orderIndex; self.weekStartDate = weekStartDate; self.templateID = templateID; self.createdAt = createdAt
        }
    }

    @Model final class AppSettingsEntity {
        @Attribute(.unique) var id: UUID
        var activeWeekStartDate: Date
        var activeWorkoutName: String
        var workoutViewModeRaw: String
        var weeklySetTarget: Int
        var unitSystemRaw: String
        var themePreferenceRaw: String
        var trackingWidgetOrderRaw: String
        var seedVersion: Int
        init(id: UUID = UUID(), activeWeekStartDate: Date = .now, activeWorkoutName: String = "", workoutViewModeRaw: String = "", weeklySetTarget: Int = 0, unitSystemRaw: String = "", themePreferenceRaw: String = "", trackingWidgetOrderRaw: String = "", seedVersion: Int = 0) {
            self.id = id; self.activeWeekStartDate = activeWeekStartDate; self.activeWorkoutName = activeWorkoutName; self.workoutViewModeRaw = workoutViewModeRaw; self.weeklySetTarget = weeklySetTarget; self.unitSystemRaw = unitSystemRaw; self.themePreferenceRaw = themePreferenceRaw; self.trackingWidgetOrderRaw = trackingWidgetOrderRaw; self.seedVersion = seedVersion
        }
    }
}

// MARK: - V2 (adds categoryRaw, weeklyTarget, cardio fields — uses live models)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            MuscleGroupEntity.self,
            ExerciseEntity.self,
            WorkoutTemplateEntity.self,
            WorkoutTemplateExerciseEntity.self,
            WeeklyExerciseEntity.self,
            CompletionLogEntity.self,
            GoalCardEntity.self,
            BodyMetricEntryEntity.self,
            PRRecordEntity.self,
            AppSettingsEntity.self,
            SectionHeaderEntity.self
        ]
    }
}

// MARK: - V3 (adds sub-muscle fields — frozen snapshot)

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            MuscleGroupEntity.self,
            ExerciseEntity.self,
            WorkoutTemplateEntity.self,
            WorkoutTemplateExerciseEntity.self,
            WeeklyExerciseEntity.self,
            CompletionLogEntity.self,
            GoalCardEntity.self,
            BodyMetricEntryEntity.self,
            PRRecordEntity.self,
            AppSettingsEntity.self,
            V3SectionHeaderEntity.self
        ]
    }

    @Model final class V3SectionHeaderEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        var orderIndex: Int
        var weekStartDate: Date?
        var templateID: UUID?
        var createdAt: Date
        init(id: UUID = UUID(), title: String = "", orderIndex: Int = 0, weekStartDate: Date? = nil, templateID: UUID? = nil, createdAt: Date = .now) {
            self.id = id; self.title = title; self.orderIndex = orderIndex; self.weekStartDate = weekStartDate; self.templateID = templateID; self.createdAt = createdAt
        }
    }
}

// MARK: - V4 (adds weeklyGoal to SectionHeaderEntity)

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            MuscleGroupEntity.self,
            ExerciseEntity.self,
            WorkoutTemplateEntity.self,
            WorkoutTemplateExerciseEntity.self,
            WeeklyExerciseEntity.self,
            CompletionLogEntity.self,
            GoalCardEntity.self,
            BodyMetricEntryEntity.self,
            PRRecordEntity.self,
            AppSettingsEntity.self,
            SectionHeaderEntity.self
        ]
    }
}

// MARK: - Migration Plan

enum WorkoutMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
}
