import SwiftData
import SwiftUI

@main
struct WorkoutTrackerApp: App {
    private let container: ModelContainer

    @StateObject private var navigation = AppNavigationState()
    @StateObject private var repository: WorkoutRepository

    init() {
        let schema = Schema([
            MuscleGroupEntity.self,
            ExerciseEntity.self,
            WorkoutTemplateEntity.self,
            WorkoutTemplateExerciseEntity.self,
            WeeklyExerciseEntity.self,
            CompletionLogEntity.self,
            GoalCardEntity.self,
            AppSettingsEntity.self
        ])

        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Unable to initialize model container: \(error)")
        }

        container = modelContainer
        _repository = StateObject(wrappedValue: WorkoutRepository(context: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(navigation)
                .environmentObject(repository)
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
