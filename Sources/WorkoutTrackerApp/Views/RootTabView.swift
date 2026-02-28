import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var navigation: AppNavigationState

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "checklist")
                }
                .tag(RootTab.workout)

            TrackingView()
                .tabItem {
                    Label("Tracking", systemImage: "chart.bar.xaxis")
                }
                .tag(RootTab.tracking)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(RootTab.library)
        }
    }
}
