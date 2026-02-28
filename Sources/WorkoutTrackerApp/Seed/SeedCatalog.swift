import Foundation

struct SeedExercise {
    let legacyID: Int
    let name: String
    let muscleGroup: String
    let sets: Int?
    let reps: Int?
    let seconds: Int?
    let weightKg: Double?
    let weightCount: Int?
}

enum SeedCatalog {
    static let seedVersion = 1

    static let defaultWeeklySetGoal = 85

    static let defaultTemplateName = "Gymmmmm - science based gainz - Hypertrophy"

    static let muscleGroups: [String] = [
        "Biceps",
        "Triceps",
        "Chest",
        "Back",
        "Delts",
        "Legs",
        "Grip / forearms",
        "Neck",
        "Abs",
        "Stretch"
    ]

    static let exercises: [SeedExercise] = [
        .init(legacyID: 1, name: "Preacher curls", muscleGroup: "Biceps", sets: 5, reps: 8, seconds: nil, weightKg: 31.8, weightCount: nil),
        .init(legacyID: 2, name: "bicep lay back dumbels - 15degr 12kg 5x8x", muscleGroup: "Biceps", sets: 5, reps: 8, seconds: nil, weightKg: 12, weightCount: nil),
        .init(legacyID: 3, name: "Close grip pull up/chin-up (biscep) 5x8x", muscleGroup: "Biceps", sets: 5, reps: 8, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 4, name: "Bicep curls 5x8x16kg / bar 31.8kg +3sets overhand", muscleGroup: "Biceps", sets: 5, reps: 8, seconds: nil, weightKg: 16, weightCount: 2),
        .init(legacyID: 5, name: "Bicep rope - 5x 8x 31kg", muscleGroup: "Biceps", sets: 5, reps: 8, seconds: nil, weightKg: 31, weightCount: nil),
        .init(legacyID: 6, name: "Pyramid 20kg", muscleGroup: "Biceps", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 7, name: "Skull crusher ez bar 25kgx10x5 push out", muscleGroup: "Triceps", sets: 5, reps: 10, seconds: nil, weightKg: 25, weightCount: nil),
        .init(legacyID: 8, name: "Dips / incline dumbel press 5x10x40kg (chest + triceps)", muscleGroup: "Triceps", sets: 5, reps: 10, seconds: nil, weightKg: 40, weightCount: nil),
        .init(legacyID: 9, name: "Overhead tricep rope 5x10x25kg /21kg deep", muscleGroup: "Triceps", sets: 5, reps: 10, seconds: nil, weightKg: 25, weightCount: nil),
        .init(legacyID: 10, name: "Tricep rope - 5x 8x 35kg", muscleGroup: "Triceps", sets: 5, reps: 8, seconds: nil, weightKg: 35, weightCount: nil),
        .init(legacyID: 11, name: "Bench press - 5x 8x 80kg", muscleGroup: "Chest", sets: 5, reps: 10, seconds: nil, weightKg: 70, weightCount: nil),
        .init(legacyID: 12, name: "Bench press (incline) (chest + tricep) - 5x 8x 60kg/52kg dumbell 30degr", muscleGroup: "Chest", sets: 5, reps: 8, seconds: nil, weightKg: 60, weightCount: nil),
        .init(legacyID: 13, name: "Machine/dumbell flies - 5x 8x 18kgx2 (chest + biceps)", muscleGroup: "Chest", sets: 5, reps: 8, seconds: nil, weightKg: 18, weightCount: 2),
        .init(legacyID: 14, name: "Landmine press (scapula)", muscleGroup: "Back", sets: 5, reps: 10, seconds: nil, weightKg: 40, weightCount: nil),
        .init(legacyID: 15, name: "Face pulls", muscleGroup: "Back", sets: 5, reps: 10, seconds: nil, weightKg: 20, weightCount: nil),
        .init(legacyID: 16, name: "Deadlift (erectors) - 5x 8x 100kg", muscleGroup: "Back", sets: 5, reps: 8, seconds: nil, weightKg: 100, weightCount: nil),
        .init(legacyID: 17, name: "Pull ups wide grip (lats+bicep) - 5x 7x", muscleGroup: "Back", sets: 5, reps: 8, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 18, name: "Cable Y Raise (lower traps) 5x 12x 35kg total (smith mach)", muscleGroup: "Back", sets: 5, reps: 12, seconds: nil, weightKg: 35, weightCount: nil),
        .init(legacyID: 19, name: "Rows 40kg", muscleGroup: "Back", sets: 5, reps: 8, seconds: nil, weightKg: 40, weightCount: nil),
        .init(legacyID: 20, name: "Weighted pull ups 5x7x12kg", muscleGroup: "Back", sets: 5, reps: 7, seconds: nil, weightKg: 12, weightCount: nil),
        .init(legacyID: 21, name: "Hyperextension low 12x5x (erectors low)", muscleGroup: "Back", sets: 5, reps: 12, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 22, name: "kelso shrugs (upper back) - 5x 12x 100kg", muscleGroup: "Back", sets: 5, reps: 12, seconds: nil, weightKg: 100, weightCount: nil),
        .init(legacyID: 23, name: "Plate scapular sweep up 5x10x5kgx2", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 5, weightCount: 2),
        .init(legacyID: 24, name: "Lateral raises (side delt) / incl. Y raises (dumbels, thumb forward) 5x10x10kg", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 10, weightCount: nil),
        .init(legacyID: 25, name: "Shoulder press / dumbell (front/side delt) below chin - 5x 10x 2x18kg", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 18, weightCount: 2),
        .init(legacyID: 26, name: "Arnold press 10kg", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 10, weightCount: 2),
        .init(legacyID: 27, name: "Shoulder cable stretch/cross over 6kg 10x 5x", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 6, weightCount: 2),
        .init(legacyID: 28, name: "Lateral raises (cable, out and back) (rear delts) 5x10x5kg", muscleGroup: "Delts", sets: 5, reps: 10, seconds: nil, weightKg: 5, weightCount: 2),
        .init(legacyID: 29, name: "Arnold side delt bench", muscleGroup: "Delts", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 30, name: "Rear delt machine flies", muscleGroup: "Delts", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 31, name: "Seated cable deadlift", muscleGroup: "Legs", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 32, name: "Leg press, 5x10x115kg deeep tand 12", muscleGroup: "Legs", sets: 5, reps: 10, seconds: nil, weightKg: 115, weightCount: nil),
        .init(legacyID: 33, name: "Leg curls - 5x10x67kg", muscleGroup: "Legs", sets: 5, reps: 10, seconds: nil, weightKg: 67, weightCount: nil),
        .init(legacyID: 34, name: "Leg extensions 5x10x70kg", muscleGroup: "Legs", sets: 5, reps: 10, seconds: nil, weightKg: 70, weightCount: nil),
        .init(legacyID: 35, name: "Squats (deep)- 5x 8x 80kg", muscleGroup: "Legs", sets: 5, reps: 8, seconds: nil, weightKg: 80, weightCount: nil),
        .init(legacyID: 36, name: "Zercher squad 40kg 12x5x", muscleGroup: "Legs", sets: 5, reps: 12, seconds: nil, weightKg: 40, weightCount: nil),
        .init(legacyID: 37, name: "Calf raises - 5x 8x 97kg", muscleGroup: "Legs", sets: 5, reps: 8, seconds: nil, weightKg: 97, weightCount: nil),
        .init(legacyID: 38, name: "Lounges - 5x 12st 60kg", muscleGroup: "Legs", sets: 5, reps: 12, seconds: nil, weightKg: 60, weightCount: nil),
        .init(legacyID: 39, name: "Curl top 5x12x6kg-max", muscleGroup: "Grip / forearms", sets: 5, reps: 20, seconds: nil, weightKg: 6, weightCount: 2),
        .init(legacyID: 40, name: "Curl bottom 5x18x10kg-max", muscleGroup: "Grip / forearms", sets: 5, reps: 20, seconds: nil, weightKg: 10, weightCount: 2),
        .init(legacyID: 41, name: "Hang / fingers 3x 50-100s / swing bars 5x back n forth", muscleGroup: "Grip / forearms", sets: 3, reps: nil, seconds: 50, weightKg: nil, weightCount: nil),
        .init(legacyID: 42, name: "Towel hang 5x 30s", muscleGroup: "Grip / forearms", sets: 5, reps: nil, seconds: 30, weightKg: nil, weightCount: nil),
        .init(legacyID: 43, name: "Falsegrip", muscleGroup: "Grip / forearms", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 44, name: "Finger push up", muscleGroup: "Grip / forearms", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 45, name: "Ridge hang", muscleGroup: "Grip / forearms", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 46, name: "Trap raises 5x14x32kgx2", muscleGroup: "Neck", sets: 5, reps: 14, seconds: nil, weightKg: 32, weightCount: 2),
        .init(legacyID: 47, name: "Plate on forehead curls", muscleGroup: "Neck", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 48, name: "Back head curls", muscleGroup: "Neck", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 49, name: "Side", muscleGroup: "Neck", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 50, name: "dragon flag", muscleGroup: "Abs", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 51, name: "leg raises 5x10x", muscleGroup: "Abs", sets: 5, reps: 10, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 52, name: "cable crunches", muscleGroup: "Abs", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 53, name: "cable twists 4x 10x 20kg", muscleGroup: "Abs", sets: 4, reps: 10, seconds: nil, weightKg: 20, weightCount: nil),
        .init(legacyID: 54, name: "leg flutters 3x 45s", muscleGroup: "Abs", sets: 3, reps: nil, seconds: 45, weightKg: nil, weightCount: nil),
        .init(legacyID: 55, name: "bicycles  3x 45s", muscleGroup: "Abs", sets: 3, reps: nil, seconds: 45, weightKg: nil, weightCount: nil),
        .init(legacyID: 56, name: "ab roll out", muscleGroup: "Abs", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 57, name: "side plank move 3x 45s", muscleGroup: "Abs", sets: 3, reps: nil, seconds: 45, weightKg: nil, weightCount: nil),
        .init(legacyID: 58, name: "mountain climbers 3x 45s", muscleGroup: "Abs", sets: 3, reps: nil, seconds: 45, weightKg: nil, weightCount: nil),
        .init(legacyID: 59, name: "russian twists  3x 45s", muscleGroup: "Abs", sets: 3, reps: nil, seconds: 45, weightKg: nil, weightCount: nil),
        .init(legacyID: 60, name: "lay on back shoulder on knees", muscleGroup: "Stretch", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 61, name: "door arms up (chest)", muscleGroup: "Stretch", sets: 3, reps: nil, seconds: 30, weightKg: nil, weightCount: nil),
        .init(legacyID: 62, name: "hammies weighted", muscleGroup: "Stretch", sets: 3, reps: nil, seconds: 30, weightKg: 40, weightCount: nil),
        .init(legacyID: 63, name: "childs pose reach sweep", muscleGroup: "Stretch", sets: nil, reps: nil, seconds: nil, weightKg: nil, weightCount: nil),
        .init(legacyID: 64, name: "lying pigeon stretches", muscleGroup: "Stretch", sets: 3, reps: nil, seconds: 30, weightKg: nil, weightCount: nil)
    ]
}
