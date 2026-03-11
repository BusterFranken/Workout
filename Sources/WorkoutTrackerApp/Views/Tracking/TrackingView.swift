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
    @State private var showingAddPRTrackerSheet = false

    @State private var isReordering = false
    @State private var showingWeighInSheet = false
    @State private var hoveredInsertionIndex: Int?
    private let chartScrollThreshold = 10
    private let chartPointWidth: CGFloat = 36

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights & Analytics")
                        .font(.sectionTitle)

                    ForEach(Array(repository.trackingWidgetOrder.enumerated()), id: \.element.id) { index, widgetID in
                        if isReordering {
                            insertionDropZone(at: index)
                        }

                        trackingWidget(widgetID)
                            .onDrag {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                                    isReordering = true
                                }
                                Haptics.soft()
                                return NSItemProvider(object: widgetID.rawValue as NSString)
                            }
                    }

                    if isReordering {
                        insertionDropZone(at: repository.trackingWidgetOrder.count)
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
            .sheet(isPresented: $showingAddPRTrackerSheet) {
                AddPRTrackerSheet(isPresented: $showingAddPRTrackerSheet)
            }
            .sheet(isPresented: $showingWeighInSheet) {
                AddWeighInSheet(isPresented: $showingWeighInSheet)
            }
            .onTapGesture {
                if isReordering {
                    isReordering = false
                    hoveredInsertionIndex = nil
                }
            }
        }
    }

    private func insertionDropZone(at index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear.opacity(0.001))

            Rectangle()
                .fill(hoveredInsertionIndex == index ? Theme.accent : .clear)
                .frame(height: hoveredInsertionIndex == index ? 3 : 1)
        }
        .contentShape(Rectangle())
        .frame(height: 14)
        .dropDestination(
            for: String.self,
            action: { items, _ in
                defer { hoveredInsertionIndex = nil }
                guard let first = items.first,
                      let source = TrackingWidgetID(rawValue: first) else {
                    return false
                }
                repository.reorderTrackingWidgets(from: source, to: index)
                return true
            },
            isTargeted: { targeted in
                if targeted {
                    hoveredInsertionIndex = index
                } else if hoveredInsertionIndex == index {
                    hoveredInsertionIndex = nil
                }
            }
        )
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
        let weeklySetTarget = repository.settings?.weeklySetTarget ?? SeedCatalog.defaultWeeklySetGoal

        return VStack(alignment: .leading, spacing: 10) {
            Text("Sets Per Week")
                .font(.headline)

            ScrollableChartContainer(
                entryCount: points.count,
                threshold: chartScrollThreshold,
                pointWidth: chartPointWidth
            ) {
                Chart(points) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Sets", point.sets)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)

                    RuleMark(y: .value("Set Goal", weeklySetTarget))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(height: 132)
            }

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
        let groups = Array(Set(points.map(\.muscleGroup))).sorted()
        let colors = muscleTrendColors(for: groups)
        let uniqueWeeksCount = Set(points.map(\.weekStart)).count

        return VStack(alignment: .leading, spacing: 10) {
            Text("Volume By Muscle Group")
                .font(.headline)

            if points.isEmpty {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ScrollableChartContainer(
                    entryCount: uniqueWeeksCount,
                    threshold: chartScrollThreshold,
                    pointWidth: chartPointWidth
                ) {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Week", point.weekStart),
                            y: .value("Sets", point.sets),
                            series: .value("Muscle", point.muscleGroup)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(colors[point.muscleGroup] ?? Theme.accent)

                        PointMark(
                            x: .value("Week", point.weekStart),
                            y: .value("Sets", point.sets)
                        )
                        .symbolSize(26)
                        .foregroundStyle(colors[point.muscleGroup] ?? Theme.accent)
                    }
                    .frame(height: 210)
                }

                if !groups.isEmpty {
                    let legendColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                    LazyVGrid(columns: legendColumns, alignment: .leading, spacing: 8) {
                        ForEach(groups, id: \.self) { group in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(colors[group] ?? Theme.accent)
                                    .frame(width: 10, height: 10)
                                Text(group)
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
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
                    let values = Array(Set(weightHistory.map { displayedWeight($0.value) })).sorted()
                    let visibleValues = Array(Set(weightHistory.suffix(10).map { displayedWeight($0.value) })).sorted()
                    let domain = paddedDomain(for: values)
                    let yAxisValues = visibleValues.isEmpty ? values : visibleValues

                    ScrollableChartContainer(
                        entryCount: weightHistory.count,
                        threshold: chartScrollThreshold,
                        pointWidth: chartPointWidth
                    ) {
                        Chart(weightHistory) { point in
                            LineMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Weight", displayedWeight(point.value))
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.accent)

                            PointMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Weight", displayedWeight(point.value))
                            )
                            .foregroundStyle(Theme.accent)
                        }
                        .chartXAxis {
                            AxisMarks(values: weightHistory.map(\.recordedAt)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisValues) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text("\(amount.formatted(.number.precision(.fractionLength(0...1)))) \(repository.unitSystem.title)")
                                    }
                                }
                            }
                            AxisMarks(position: .trailing, values: yAxisValues) { value in
                                AxisTick()
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text("\(amount.formatted(.number.precision(.fractionLength(0...1)))) \(repository.unitSystem.title)")
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: domain)
                        .frame(height: 120)
                    }
                }

                if let latest = weightHistory.last {
                    Text("Latest: \(displayedWeight(latest.value), specifier: "%.1f") \(repository.unitSystem.title)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
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
                    let values = Array(Set(bodyFatHistory.map(\.value))).sorted()
                    let visibleValues = Array(Set(bodyFatHistory.suffix(10).map(\.value))).sorted()
                    let domain = paddedDomain(for: values)
                    let yAxisValues = visibleValues.isEmpty ? values : visibleValues

                    ScrollableChartContainer(
                        entryCount: bodyFatHistory.count,
                        threshold: chartScrollThreshold,
                        pointWidth: chartPointWidth
                    ) {
                        Chart(bodyFatHistory) { point in
                            LineMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Visual Body Fat", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.orange)

                            PointMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Visual Body Fat", point.value)
                            )
                            .foregroundStyle(.orange)
                        }
                        .chartXAxis {
                            AxisMarks(values: bodyFatHistory.map(\.recordedAt)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisValues) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text("\(amount.formatted(.number.precision(.fractionLength(0...1))))%")
                                    }
                                }
                            }
                            AxisMarks(position: .trailing, values: yAxisValues) { value in
                                AxisTick()
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text("\(amount.formatted(.number.precision(.fractionLength(0...1))))%")
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: domain)
                        .frame(height: 120)
                    }
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
            HStack {
                Text("Classic PR Tracking")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddPRTrackerSheet = true
                    Haptics.selection()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add PR to track")
            }

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
                            Text("kg")
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

    private func paddedDomain(for values: [Double]) -> ClosedRange<Double> {
        guard let minValue = values.first, let maxValue = values.last else {
            return 0...1
        }
        let span = max(maxValue - minValue, 1)
        let padding = max(span * 0.1, 0.5)
        return (minValue - padding)...(maxValue + padding)
    }

    private func muscleTrendColors(for groups: [String]) -> [String: Color] {
        let palette: [Color] = [
            .pink,
            .blue,
            .green,
            .orange,
            .red,
            .teal,
            .indigo,
            .mint,
            .brown
        ]

        var mapping: [String: Color] = [:]
        for (index, group) in groups.enumerated() {
            mapping[group] = palette[index % palette.count]
        }
        return mapping
    }
}

private struct ScrollableChartContainer<Content: View>: View {
    let entryCount: Int
    let threshold: Int
    let pointWidth: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if entryCount > threshold {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        content()
                            .frame(width: CGFloat(entryCount) * pointWidth)
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("chart-end-\(entryCount)")
                    }
                }
                .onAppear {
                    proxy.scrollTo("chart-end-\(entryCount)", anchor: .trailing)
                }
                .onChange(of: entryCount) { _, newCount in
                    proxy.scrollTo("chart-end-\(newCount)", anchor: .trailing)
                }
            }
        } else {
            content()
        }
    }
}

private struct AddPRTrackerSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Binding var isPresented: Bool

    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("PR Name") {
                    TextField("e.g. Incline Bench Press", text: $label)
                }
            }
            .navigationTitle("Add PR Tracker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        repository.addPRTracker(label: label)
                        isPresented = false
                        Haptics.success()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
                        let yValues = Array(Set(history.map(\.value))).sorted()
                        let visibleValues = Array(Set(history.suffix(10).map(\.value))).sorted()
                        let minY = yValues.first ?? 0
                        let maxY = yValues.last ?? minY
                        let span = max(maxY - minY, 1)
                        let padding = max(span * 0.1, 0.5)
                        let yAxisValues = visibleValues.isEmpty ? yValues : visibleValues

                        ScrollableChartContainer(entryCount: history.count, threshold: 10, pointWidth: 36) {
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
                            .chartXAxis {
                                AxisMarks(values: history.map(\.date)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: yAxisValues) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let amount = value.as(Double.self) {
                                            Text("\(amount.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                        }
                                    }
                                }
                                AxisMarks(position: .trailing, values: yAxisValues) { value in
                                    AxisTick()
                                    AxisValueLabel {
                                        if let amount = value.as(Double.self) {
                                            Text("\(amount.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                        }
                                    }
                                }
                            }
                            .chartYScale(domain: (minY - padding)...(maxY + padding))
                            .frame(height: 180)
                        }
                    }
                }

                Section("Add New PR") {
                    TextField("kg", text: $value)
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
