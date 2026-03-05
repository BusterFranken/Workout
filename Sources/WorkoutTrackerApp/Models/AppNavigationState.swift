import Foundation

enum RootTab: Hashable {
    case workout
    case tracking
    case library
    case more
}

final class AppNavigationState: ObservableObject {
    @Published var selectedTab: RootTab = .workout
}
