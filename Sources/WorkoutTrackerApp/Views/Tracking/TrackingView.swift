import Charts
import SwiftUI

private struct SelectedPRItem: Identifiable {
    let id = UUID()
    let label: String
}

struct TrackingView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @State private var expandedGroups: Set<UUID> = []
    @State private var selectedExercise: WeeklyExerciseEntity?
    @State private var selectedPRItem: SelectedPRItem?

    @State private var isReordering = false
    @State private var showingWeighInSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights & Analytics")
                        .font(.sectionTitle)

                    ForEach(repository.trackingWidgetOrder) { widgetID in
                        trackingWidget(widgetID)
                            .draggable(widgetID.rawValue)
                            .dropDestination(for: String.self) { items, _ in
                                guard isReordering,
                                      let first = items.first,
                                      let source = TrackingWidgetID(rawValue: first),
                                      source != widgetID,
                                      let destination = repository.trackingWidgetOrder.firstIndex(of: widgetID)
                                else {
                                    return false
                                }
                                repository.reorderTrackingWidgets(from: source, to: destination)
                                return true
                            }
                            .onLongPressGesture {
                                withAnimation(.spring) {
                                    isReordering = true
                                }
                                Haptics.soft()
                            }
                            .wiggle(isReordering)
                    }

                    if isReordering {
                        Text("Drag cards to reorder")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Tracking")
            .sheet(item: $selectedExercise) { row in
                ExerciseDetailSheet(exercise: row)
            }
            .sheet(item: $selectedPRItem) { item in
                PRDetailSheet(label: item.label)
            }
            .sheet(isPresented: $showingWeighInSheet) {
                AddWeighInSheet(isPresented: $showingWeighInSheet)
            }
            .onTapGesture {
                if isReordering {
                    isReordering = false
                }
            }
        }
    }

    @ViewBuilder
    private func trackingWidget(_ widget: TrackingWidgetID) -> some View {
        switch widget {
        case .weeklySets:
            weeklySetsCard
        case .workoutDays:
            WorkoutHeatmapView(points: repository.allTimeActivity())
        case .muscleTrend:
            muscleTrendCard
        case .currentWeekByMuscle:
            muscleVolumeCard
        case .bodyMetrics:
            bodyMetricsCard
        case .classicPRs:
            prCard
        }
    }

    private var weeklySetsCard: some View {
        let points = repository.weeklySetTrend(weeks: 10)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Sets Per Week")
                .font(.headline)

            Chart(points) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Sets", point.sets)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
            }
            .frame(height: 200)

            Text("Active week total: \(repository.totalSetsDoneThisWeek)")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
    }

    private var muscleTrendCard: some View {
        let points = repository.muscleVolumeTrend(weeks: 8)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Volume By Muscle Group")
                .font(.headline)

            if points.isEmpty {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Week", point.weekStart),
                        y: .value("Sets", point.sets),
                        series: .value("Muscle", point.muscleGroup)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", point.weekStart),
                        y: .value("Sets", point.sets)
                    )
                    .symbolSize(26)
                }
                .frame(height: 210)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
    }

    private var muscleVolumeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Week By Muscle")
                .font(.headline)

            ForEach(repository.currentWeekMuscleVolume()) { item in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedGroups.contains(item.id) },
                        set: { value in
                            if value {
                                expandedGroups.insert(item.id)
                            } else {
                                expandedGroups.remove(item.id)
                            }
                        }
                    )
                ) {
                    ForEach(item.exerciseProgress) { progress in
                        Button {
                            selectedExercise = progress.exercise
                        } label: {
                            HStack {
                                Text(progress.exercise.name.isEmpty ? "Untitled Exercise" : progress.exercise.name)
                                Spacer()
                                Text("\(progress.doneSets) st")
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                } label: {
                    HStack {
                        Text(item.muscleGroup.name)
                        Spacer()
                        Text("\(item.sets) sets")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
    }

    private var bodyMetricsCard: some View {
        let weightHistory = repository.bodyMetricHistory(kind: .scaleWeight, lastDays: 30)
        let bodyFatHistory = repository.bodyMetricHistory(kind: .visualBodyFat, lastDays: 30)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Body Metrics")
                    .font(.headline)
                Spacer()
                Button("Add Weigh-In") {
                    showingWeighInSheet = true
                    Haptics.selection()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Scale Weight")
                    .font(.subheadline.weight(.semibold))

                if weightHistory.isEmpty {
                    Text("No weigh-ins yet")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Chart(weightHistory) { point in
                        LineMark(
                            x: .value("Date", point.recordedAt),
                            y: .value("Weight", displayedWeight(point.value))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 120)

                    if let latest = weightHistory.last {
                        Text("Latest: \(displayedWeight(latest.value), specifier: "%.1f") \(repository.unitSystem.title)")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Visual Body Fat")
                    .font(.subheadline.weight(.semibold))

                if bodyFatHistory.isEmpty {
                    Text("No entries yet")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Chart(bodyFatHistory) { point in
                        LineMark(
                            x: .value("Date", point.recordedAt),
                            y: .value("Visual Body Fat", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 120)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
    }

    private var prCard: some View {
        let prs = repository.classicPRs()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Classic PR Tracking")
                .font(.headline)

            ForEach(prs) { pr in
                Button {
                    selectedPRItem = SelectedPRItem(label: pr.label)
                    Haptics.selection()
                } label: {
                    HStack {
                        Text(pr.label)
                        Spacer()
                        if pr.bestLoad > 0 {
                            Text("\(Int(pr.bestLoad))")
                                .font(.headline.monospacedDigit())
                            Text("kg*reps")
                                .foregroundStyle(Theme.secondaryText)
                        } else {
                            Text("--")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
    }

    private func displayedWeight(_ kg: Double) -> Double {
        switch repository.unitSystem {
        case .kg:
            return kg
        case .lb:
            return kg * 2.2046226218
        }
    }
}

private struct AddWeighInSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Binding var isPresented: Bool

    @State private var weight: String = ""
    @State private var bodyFat: String = ""

    /// Accept both comma and dot as decimal separator.
    private func parseDecimal(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scale Weight") {
                    TextField("\(repository.unitSystem.title.uppercased())", text: $weight)
                        .decimalPadKeyboardIfAvailable()
                }

                Section("Visual Body Fat") {
                    TextField("Optional", text: $bodyFat)
                        .decimalPadKeyboardIfAvailable()
                }
            }
            .navigationTitle("Add Weigh-In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        isPresented = false
                        Haptics.success()
                    }
                    .disabled(parseDecimal(weight) == nil)
                }
            }
        }
    }

    private func save() {
        guard let rawWeight = parseDecimal(weight) else { return }

        let kgWeight: Double
        switch repository.unitSystem {
        case .kg:
            kgWeight = rawWeight
        case .lb:
            kgWeight = rawWeight / 2.2046226218
        }

        repository.addBodyMetric(kind: .scaleWeight, value: kgWeight)

        if let bf = parseDecimal(bodyFat), bf > 0 {
            repository.addBodyMetric(kind: .visualBodyFat, value: bf)
        }
    }
}

private struct PRDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let label: String

    @State private var value = ""
    @State private var note = ""

    private var history: [PRPoint] {
        repository.prHistory(for: label)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Progression") {
                    if history.isEmpty {
                        Text("No PR history yet")
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        Chart(history) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("PR", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.accent)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("PR", point.value)
                            )
                            .foregroundStyle(Theme.accent)
                        }
                        .frame(height: 180)
                    }
                }

                Section("Add New PR") {
                    TextField("kg*reps", text: $value)
                        .decimalPadKeyboardIfAvailable()
                    TextField("Optional note", text: $note)

                    Button("Save PR") {
                        if let parsed = Double(value), parsed > 0 {
                            repository.addPRRecord(label: label, value: parsed, notes: note)
                            value = ""
                            note = ""
                            Haptics.success()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(Double(value) == nil)
                }
            }
            .navigationTitle(label)
            .inlineNavigationTitleDisplayModeIfAvailable()
            .platformInsetGroupedListStyle()
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

    @ViewBuilder
    func inlineNavigationTitleDisplayModeIfAvailable() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func decimalPadKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
