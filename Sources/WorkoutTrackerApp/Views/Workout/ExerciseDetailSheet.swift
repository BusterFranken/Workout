import Charts
import SwiftUI

struct ExerciseDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity

    private var logs: [CompletionLogEntity] {
        repository.progressionLogs(for: exercise)
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
                            Chart(logs) { point in
                                let value = displayedWeight(from: point.weightKgSnapshot)
                                LineMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Weight", value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Theme.accent)

                                PointMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Weight", value)
                                )
                                .foregroundStyle(Theme.accent)
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel()
                                }
                            }
                            .frame(height: 180)
                        }

                        chartCard(title: "Load Progression (kg x reps)") {
                            Chart(logs) { point in
                                LineMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Load", point.loadSnapshot ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.black)

                                PointMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Load", point.loadSnapshot ?? 0)
                                )
                                .foregroundStyle(Color.black)
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel()
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Exercise")
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
        let secondary = exercise.secondaryMuscleGroupsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if secondary.isEmpty {
            return exercise.muscleGroupName
        }
        return "\(exercise.muscleGroupName) • Secondary: \(secondary.joined(separator: ", "))"
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
}
