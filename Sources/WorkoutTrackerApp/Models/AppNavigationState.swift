import Foundation

enum RootTab: Hashable {
    case workout
    case tracking
    case library
}

final class AppNavigationState: ObservableObject {
    @Published var selectedTab: RootTab = .workout
}
