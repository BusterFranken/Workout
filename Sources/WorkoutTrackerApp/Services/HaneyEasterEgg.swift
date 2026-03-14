import Foundation

enum HaneyTrigger: Hashable {
    case junkVolume
    case noProgression
    case egoLifting
}

struct HaneyQuote {
    let trigger: HaneyTrigger
    let text: String
    let attribution = "- Lee Haney"
}

final class HaneyEasterEgg {

    private var firedTriggers: Set<HaneyTrigger> = []

    private static let isolationKeywords = [
        "curl", "lateral raise", "fly", "flies", "extension", "kickback",
        "raise", "rope", "skull crush", "concentration", "shrug",
        "face pull", "cable cross", "pullover"
    ]

    private static let quotes: [HaneyTrigger: [String]] = [
        .egoLifting: [
            "Stimulate, don't annihilate.",
            "Exercise to stimulate, not to annihilate.",
            "I trained to stress the muscle, not to impress the people around me with heavy weights."
        ],
        .junkVolume: [
            "The name of the game is quality, not quantity.",
            "My goal was always to stimulate the muscle, not push it to failure — doing so only increased my chances of injury.",
            "The more advanced you get, the more time you need to rest and recover between workouts."
        ],
        .noProgression: [
            "The key to building massive, powerful muscles is to doggedly increase the training weights you use.",
            "Set small goals and build upon them.",
            "Growth happens when you train smart, not just hard."
        ]
    ]

    // MARK: - Public

    func evaluate(
        exercise: EvaluationInput,
        completionLogs: [CompletionLogEntry],
        progressionLogs: [ProgressionLogEntry]
    ) -> HaneyQuote? {
        // Priority: ego lifting > junk volume > no progression
        if let q = checkEgoLifting(exercise: exercise) { return q }
        if let q = checkJunkVolume(exercise: exercise, completionLogs: completionLogs) { return q }
        if let q = checkNoProgression(exercise: exercise, progressionLogs: progressionLogs) { return q }
        return nil
    }

    // MARK: - Input types (lightweight wrappers so we don't depend on SwiftData entities)

    struct EvaluationInput {
        let name: String
        let reps: Int?
        let categoryRaw: String
        let muscleGroupID: UUID?
    }

    struct CompletionLogEntry {
        let muscleGroupID: UUID?
        let completedAt: Date
        let setsSnapshot: Int?
    }

    struct ProgressionLogEntry {
        let exerciseID: UUID?
        let weekStartDate: Date
        let weightKgSnapshot: Double?
    }

    // MARK: - Trigger checks

    private func checkEgoLifting(exercise: EvaluationInput) -> HaneyQuote? {
        guard !firedTriggers.contains(.egoLifting) else { return nil }
        guard exercise.categoryRaw == "exercise" else { return nil }
        guard let reps = exercise.reps, reps >= 1, reps <= 3 else { return nil }

        let nameLower = exercise.name.lowercased()
        let isIsolation = Self.isolationKeywords.contains { nameLower.contains($0) }
        guard isIsolation else { return nil }

        firedTriggers.insert(.egoLifting)
        return makeQuote(for: .egoLifting)
    }

    private func checkJunkVolume(
        exercise: EvaluationInput,
        completionLogs: [CompletionLogEntry]
    ) -> HaneyQuote? {
        guard !firedTriggers.contains(.junkVolume) else { return nil }
        guard let muscleGroupID = exercise.muscleGroupID else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todaySets = completionLogs
            .filter { log in
                log.muscleGroupID == muscleGroupID
                    && calendar.startOfDay(for: log.completedAt) == today
            }
            .compactMap(\.setsSnapshot)
            .reduce(0, +)

        guard todaySets >= 15 else { return nil }

        firedTriggers.insert(.junkVolume)
        return makeQuote(for: .junkVolume)
    }

    private func checkNoProgression(
        exercise: EvaluationInput,
        progressionLogs: [ProgressionLogEntry]
    ) -> HaneyQuote? {
        guard !firedTriggers.contains(.noProgression) else { return nil }
        guard let exerciseID = exercise.muscleGroupID != nil ? exercise.muscleGroupID : nil else { return nil }

        // Group by weekStartDate, take the weight from each week
        let weeklyWeights: [Date: Double] = progressionLogs
            .filter { $0.exerciseID == exerciseID }
            .reduce(into: [:]) { dict, log in
                if let w = log.weightKgSnapshot {
                    dict[log.weekStartDate] = w
                }
            }

        // Need at least 3 distinct weeks
        let sortedWeeks = weeklyWeights.keys.sorted().suffix(3)
        guard sortedWeeks.count >= 3 else { return nil }

        let weights = sortedWeeks.compactMap { weeklyWeights[$0] }
        guard weights.count == 3 else { return nil }

        // All same weight?
        let allSame = weights.dropFirst().allSatisfy { $0 == weights.first }
        guard allSame else { return nil }

        firedTriggers.insert(.noProgression)
        return makeQuote(for: .noProgression)
    }

    // MARK: - Helpers

    private func makeQuote(for trigger: HaneyTrigger) -> HaneyQuote {
        let pool = Self.quotes[trigger] ?? ["Stimulate, don't annihilate."]
        let text = pool.randomElement() ?? pool[0]
        return HaneyQuote(trigger: trigger, text: text)
    }
}
