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

            MoreView()
                .tabItem {
                    Label("Settings", systemImage: "ellipsis.circle")
                }
                .tag(RootTab.more)
        }
    }
}

private struct MoreView: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @State private var accentOption = Theme.accentOption
    @State private var customAccentColor = Theme.customAccentColor
    @State private var showingHighlightColorSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        WorkoutsLogoMark()
                            .frame(width: 42, height: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workouts")
                                .font(.headline)
                            Text("Minimal, focused strength tracking")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preferences") {
                    Picker("Units", selection: unitBinding) {
                        ForEach(UnitSystem.allCases) { unit in
                            Text(unit.title.uppercased()).tag(unit)
                        }
                    }
                    .onChange(of: repository.unitSystem) { _, _ in
                        Haptics.selection()
                    }

                    Picker("Theme", selection: themeBinding) {
                        Text("System").tag(AppThemePreference.system)
                        Text("Light").tag(AppThemePreference.light)
                        Text("Dark").tag(AppThemePreference.dark)
                    }
                    .onChange(of: repository.themePreference) { _, _ in
                        Haptics.selection()
                    }

                    Button {
                        showingHighlightColorSheet = true
                    } label: {
                        HStack {
                            Text("Highlight Color")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accentOption.color)
                                    .frame(width: 10, height: 10)
                                Text(accentOption.title)
                                    .foregroundStyle(accentOption.color)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: accentOption) { _, newOption in
                        Theme.updateAccentOption(newOption)
                        Haptics.selection()
                    }

                    if accentOption == .custom {
                        ColorPicker("Custom Color", selection: $customAccentColor, supportsOpacity: false)
                            .onChange(of: customAccentColor) { _, newColor in
                                Theme.updateCustomAccentColor(newColor)
                            }
                    }
                }

                Section("Support") {
                    NavigationLink("Contact") {
                        ContactView()
                    }
                }

                Section("Data") {
                    Button(simulationButtonTitle) {
                        if repository.hasSimulatedActivity {
                            repository.removeSimulatedActivityHistory()
                            Haptics.warning()
                        } else {
                            repository.simulateActivityHistory()
                            Haptics.success()
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(versionLabel)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .platformInsetGroupedListStyle()
            .onAppear {
                accentOption = Theme.accentOption
                customAccentColor = Theme.customAccentColor
            }
            .sheet(isPresented: $showingHighlightColorSheet) {
                NavigationStack {
                    List {
                        Section("Standard Colors") {
                            ForEach(AccentColorOption.allCases) { option in
                                Button {
                                    accentOption = option
                                    showingHighlightColorSheet = false
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 10, height: 10)
                                        Text(option.title)
                                            .foregroundStyle(option.color)
                                        Spacer()
                                        if accentOption == option {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .navigationTitle("Highlight Color")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingHighlightColorSheet = false }
                        }
                    }
                }
            }
        }
    }

    private var unitBinding: Binding<UnitSystem> {
        Binding(
            get: { repository.unitSystem },
            set: { repository.updateUnitSystem($0) }
        )
    }

    private var themeBinding: Binding<AppThemePreference> {
        Binding(
            get: { repository.themePreference },
            set: { repository.updateThemePreference($0) }
        )
    }

    private var versionLabel: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var simulationButtonTitle: String {
        repository.hasSimulatedActivity ? "Remove simulated activity" : "Simulate activity"
    }
}

private struct ContactView: View {
    var body: some View {
        List {
            Section("Contact") {
                Text("Report bugs or request features using one of these options:")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)

                Link(
                    "Email: busterfranken+workout@gmail.com",
                    destination: URL(string: "mailto:busterfranken+workout@gmail.com")!
                )

                Link(
                    "WhatsApp: +31 624877967",
                    destination: URL(string: "https://wa.me/31624877967")!
                )
            }
        }
        .navigationTitle("Contact")
        .platformInsetGroupedListStyle()
    }
}

private struct WorkoutsLogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.primaryText.opacity(0.1), lineWidth: 1)
                )

            VStack(spacing: 4) {
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 6)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.primaryText)
                    .frame(width: 10, height: 14)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 6)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func platformInsetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}
