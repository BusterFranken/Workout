import SwiftData
import SwiftUI

@main
struct WorkoutsApp: App {
    private let container: ModelContainer

    @StateObject private var navigation = AppNavigationState()
    @StateObject private var repository: WorkoutRepository
    @State private var accentRefreshToken = UUID()

    #if DEBUG
    /// Flip to `true` during development to wipe the database on next launch.
    private static let forceResetDatabase = false
    #endif

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
            AppSettingsEntity.self,
            SectionHeaderEntity.self
        ])

        #if DEBUG
        if Self.forceResetDatabase {
            Self.deleteStoreFiles()
        }
        #endif

        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: WorkoutMigrationPlan.self
            )
        } catch {
            // Delete corrupt/incompatible store as last resort
            Self.deleteStoreFiles()
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: WorkoutMigrationPlan.self
                )
            } catch {
                fatalError("Unable to initialize model container after reset: \(error)")
            }
        }

        container = modelContainer
        _repository = StateObject(wrappedValue: WorkoutRepository(context: modelContainer.mainContext))
    }

    private static func deleteStoreFiles() {
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: URL(filePath: url.path() + "-shm"))
        try? FileManager.default.removeItem(at: URL(filePath: url.path() + "-wal"))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                    .environmentObject(navigation)
                    .environmentObject(repository)
                    .tint(Theme.accent)
                    .preferredColorScheme(colorScheme)
                    .id(accentRefreshToken)
                    .onReceive(NotificationCenter.default.publisher(for: .themeAccentDidChange)) { _ in
                        accentRefreshToken = UUID()
                    }

                if let quote = repository.activeHaneyQuote {
                    HaneyOverlayView(quote: quote) {
                        repository.activeHaneyQuote = nil
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: repository.activeHaneyQuote != nil)
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
        AppSettingsEntity.self,
        SectionHeaderEntity.self
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
