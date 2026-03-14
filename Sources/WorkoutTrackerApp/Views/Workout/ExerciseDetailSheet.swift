import Charts
import SwiftUI

struct ExerciseDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity
    @State private var showingEditor = false
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
                                    .foregroundStyle(Color.black)

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Load", point.value)
                                    )
                                    .foregroundStyle(Color.black)
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
            .navigationTitle("Exercise")
            .sheet(isPresented: $showingEditor) {
                ExerciseEditorSheet(isPresented: $showingEditor, exercise: exercise)
                    .environmentObject(repository)
            }
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
