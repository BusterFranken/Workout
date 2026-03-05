import SwiftData
import SwiftUI

@main
struct WorkoutsApp: App {
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
            BodyMetricEntryEntity.self,
            PRRecordEntity.self,
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
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)
    }

    private var colorScheme: ColorScheme? {
        switch repository.themePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
#if DEBUG
#Preview("Root Tab") {
    let schema = Schema([
        MuscleGroupEntity.self,
        ExerciseEntity.self,
        WorkoutTemplateEntity.self,
        WorkoutTemplateExerciseEntity.self,
        WeeklyExerciseEntity.self,
        CompletionLogEntity.self,
        GoalCardEntity.self,
        BodyMetricEntryEntity.self,
        PRRecordEntity.self,
        AppSettingsEntity.self
    ])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let navigation = AppNavigationState()
    let repository = WorkoutRepository(context: container.mainContext)

    return RootTabView()
        .environmentObject(navigation)
        .environmentObject(repository)
        .modelContainer(container)
        .tint(Theme.accent)
}
#endif

