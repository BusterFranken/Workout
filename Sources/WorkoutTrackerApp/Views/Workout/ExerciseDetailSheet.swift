import Charts
import SwiftUI

private struct SetRowState: Identifiable {
    let id = UUID()
    var repsText: String
    var weightText: String
}

struct ExerciseDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity
    @State private var showingEditor = false
    @State private var selectedImage: IdentifiableImageData?
    @State private var detailedLogExpanded = true
    @State private var setRows: [SetRowState] = []
    @State private var hasLoadedSetRows = false
    private let chartScrollThreshold = 10
    private let chartPointWidth: CGFloat = 36

    private struct ProgressPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var logs: [CompletionLogEntity] {
        repository.progressionLogs(for: exercise)
    }

    private var weightHistory: [ProgressPoint] {
        logs.compactMap { log in
            let value = displayedWeight(from: log.weightKgSnapshot)
            guard value > 0 else { return nil }
            return ProgressPoint(date: log.completedAt, value: value)
        }
    }

    private var loadHistory: [ProgressPoint] {
        logs.compactMap { log in
            guard let value = log.loadSnapshot, value > 0 else { return nil }
            return ProgressPoint(date: log.completedAt, value: displayedWeight(from: value))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name.isEmpty ? "Untitled Exercise" : exercise.name)
                            .font(.title.bold())
                        Text(primaryAndSecondaryLine)
                            .foregroundStyle(Theme.secondaryText)
                    }

                    if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        chartCard(title: "Note") {
                            Text(exercise.notes)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if exercise.category == .exercise {
                        detailedLogCard
                    }

                    if logs.isEmpty {
                        emptyCard("No completed logs yet. Check off this exercise to start tracking progression.")
                    } else {
                        chartCard(title: "Weight Progression (\(repository.unitSystem.title))") {
                            let yValues = Array(Set(weightHistory.map(\.value))).sorted()
                            let visibleValues = Array(Set(weightHistory.suffix(10).map(\.value))).sorted()
                            let domain = paddedDomain(for: yValues)
                            let yAxisValues = visibleValues.isEmpty ? yValues : visibleValues

                            ScrollableChartContainer(
                                entryCount: weightHistory.count,
                                threshold: chartScrollThreshold,
                                pointWidth: chartPointWidth
                            ) {
                                Chart(weightHistory) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Weight", point.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Theme.accent)

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Weight", point.value)
                                    )
                                    .foregroundStyle(Theme.accent)
                                }
                                .chartXAxis {
                                    AxisMarks(values: weightHistory.map(\.date)) { value in
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
                                .frame(height: 180)
                            }
                        }

                        chartCard(title: "Load Progression (\(repository.unitSystem.title) x reps)") {
                            let yValues = Array(Set(loadHistory.map(\.value))).sorted()
                            let visibleValues = Array(Set(loadHistory.suffix(10).map(\.value))).sorted()
                            let domain = paddedDomain(for: yValues)
                            let yAxisValues = visibleValues.isEmpty ? yValues : visibleValues

                            ScrollableChartContainer(
                                entryCount: loadHistory.count,
                                threshold: chartScrollThreshold,
                                pointWidth: chartPointWidth
                            ) {
                                Chart(loadHistory) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Load", point.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Theme.primaryText)

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Load", point.value)
                                    )
                                    .foregroundStyle(Theme.primaryText)
                                }
                                .chartXAxis {
                                    AxisMarks(values: loadHistory.map(\.date)) { value in
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
                                                Text(amount.formatted(.number.precision(.fractionLength(0...1))))
                                            }
                                        }
                                    }
                                    AxisMarks(position: .trailing, values: yAxisValues) { value in
                                        AxisTick()
                                        AxisValueLabel {
                                            if let amount = value.as(Double.self) {
                                                Text(amount.formatted(.number.precision(.fractionLength(0...1))))
                                            }
                                        }
                                    }
                                }
                                .chartYScale(domain: domain)
                                .frame(height: 180)
                            }
                        }
                    }

                    if !exercise.instructionSteps.isEmpty || !exercise.instructionImages.isEmpty {
                        chartCard(title: "Instructions") {
                            VStack(alignment: .leading, spacing: 12) {
                                #if canImport(UIKit)
                                if !exercise.instructionImages.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(Array(exercise.instructionImages.enumerated()), id: \.offset) { index, data in
                                                if let uiImage = UIImage(data: data) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        .onTapGesture {
                                                            selectedImage = IdentifiableImageData(data: data)
                                                        }
                                                }
                                            }
                                        }
                                    }
                                }
                                #endif

                                if !exercise.instructionSteps.isEmpty {
                                    ForEach(Array(exercise.instructionSteps.enumerated()), id: \.offset) { index, step in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Theme.secondaryText)
                                                .frame(width: 24, alignment: .trailing)
                                            Text(step)
                                                .font(.subheadline)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        showingEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Exercise")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .appCard()
                }
                .padding()
            }
            .background(Theme.background)
            .onAppear {
                if !hasLoadedSetRows && exercise.category == .exercise {
                    loadSetRows()
                }
            }
            .navigationTitle("Exercise")
            .sheet(isPresented: $showingEditor) {
                ExerciseEditorSheet(isPresented: $showingEditor, exercise: exercise)
                    .environmentObject(repository)
            }
            #if canImport(UIKit)
            .sheet(item: $selectedImage) { item in
                NavigationStack {
                    if let uiImage = UIImage(data: item.data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { selectedImage = nil }
                                }
                            }
                    }
                }
            }
            #endif
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color.clear)
        .appCard()
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Theme.secondaryText)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .appCard()
    }

    private var primaryAndSecondaryLine: String {
        let primaryLabel: String
        if let sub = exercise.subMuscleName, !sub.isEmpty {
            primaryLabel = "\(exercise.muscleGroupName) (\(sub))"
        } else {
            primaryLabel = exercise.muscleGroupName
        }

        let secondary = exercise.secondaryMuscleGroupsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if secondary.isEmpty {
            return primaryLabel
        }
        return "\(primaryLabel) • Secondary: \(secondary.joined(separator: ", "))"
    }

    private func displayedWeight(from kg: Double?) -> Double {
        guard let kg else { return 0 }
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

    // MARK: - Detailed Log

    private var detailedLogCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    detailedLogExpanded.toggle()
                }
                if detailedLogExpanded && !hasLoadedSetRows {
                    loadSetRows()
                }
            } label: {
                HStack {
                    Text("Detailed Log")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .rotationEffect(.degrees(detailedLogExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()

            if detailedLogExpanded {
                VStack(spacing: 12) {
                    Stepper("Sets: \(setRows.count)", onIncrement: {
                        let defaultReps = exercise.reps ?? 10
                        let defaultWeight = displayedWeightString(from: exercise.weightKg)
                        setRows.append(SetRowState(repsText: "\(defaultReps)", weightText: defaultWeight))
                    }, onDecrement: {
                        guard setRows.count > 1 else { return }
                        setRows.removeLast()
                    })
                    .font(.subheadline.weight(.medium))

                    HStack(spacing: 0) {
                        Text("Set")
                            .frame(width: 36, alignment: .leading)
                        Text("Reps")
                            .frame(maxWidth: .infinity)
                        Text("Weight (\(repository.unitSystem.title))")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)

                    ForEach(Array(setRows.enumerated()), id: \.element.id) { index, _ in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.secondaryText)
                                .frame(width: 28, alignment: .center)

                            HStack(spacing: 0) {
                                TextField("0", text: $setRows[index].repsText)
                                    .decimalPadKeyboardIfAvailable()
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text("r")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Theme.mutedSurface)
                            )

                            HStack(spacing: 0) {
                                TextField("BW", text: $setRows[index].weightText)
                                    .numbersAndPunctuationKeyboardIfAvailable()
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text(repository.unitSystem.title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Theme.mutedSurface)
                            )
                        }
                    }

                    Button {
                        saveDetailedLog()
                    } label: {
                        Text("Save Log")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                .padding([.horizontal, .bottom])
            }
        }
        .background(Color.clear)
        .appCard()
    }

    private func loadSetRows() {
        hasLoadedSetRows = true

        if let log = repository.currentWeekDetailedLog(for: exercise),
           let details = log.setDetails {
            setRows = details.map { detail in
                SetRowState(
                    repsText: "\(detail.reps)",
                    weightText: displayedWeightString(from: detail.weightKg)
                )
            }
            return
        }

        let numSets = exercise.sets ?? 3
        let defaultReps = exercise.reps ?? 10
        let defaultWeight = displayedWeightString(from: exercise.weightKg)
        setRows = (0..<numSets).map { _ in
            SetRowState(repsText: "\(defaultReps)", weightText: defaultWeight)
        }
    }

    private func saveDetailedLog() {
        let details = setRows.compactMap { row -> SetDetail? in
            guard let reps = Int(row.repsText.filter { $0.isNumber }), reps > 0 else { return nil }
            let weightKg = Formatting.parseWeightEntry(row.weightText, unit: repository.unitSystem)
            return SetDetail(reps: reps, weightKg: weightKg)
        }
        guard !details.isEmpty else { return }
        repository.saveDetailedLog(for: exercise, setDetails: details)
    }

    private func displayedWeightString(from kg: Double?) -> String {
        guard let kg, kg > 0 else { return "" }
        switch repository.unitSystem {
        case .kg:
            return kg.rounded() == kg ? "\(Int(kg))" : String(format: "%.1f", kg)
        case .lb:
            let lb = kg * 2.2046226218
            return lb.rounded() == lb ? "\(Int(lb))" : String(format: "%.1f", lb)
        }
    }
}

private struct IdentifiableImageData: Identifiable {
    let id = UUID()
    let data: Data
}

private extension View {
    @ViewBuilder
    func numbersAndPunctuationKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.numbersAndPunctuation)
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
                            .id("exercise-chart-end-\(entryCount)")
                    }
                }
                .onAppear {
                    proxy.scrollTo("exercise-chart-end-\(entryCount)", anchor: .trailing)
                }
                .onChange(of: entryCount) { _, newCount in
                    proxy.scrollTo("exercise-chart-end-\(newCount)", anchor: .trailing)
                }
            }
        } else {
            content()
        }
    }
}
