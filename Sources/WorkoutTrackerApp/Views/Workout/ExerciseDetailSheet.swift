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
                        Text(exercise.muscleGroupName)
                            .foregroundStyle(Theme.secondaryText)
                    }

                    if logs.isEmpty {
                        emptyCard("No completed logs yet. Check off this exercise to start tracking progression.")
                    } else {
                        chartCard(title: "Weight Progression (kg)") {
                            Chart(logs) { point in
                                LineMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Weight", point.weightKgSnapshot ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Theme.accent)

                                PointMark(
                                    x: .value("Date", point.completedAt),
                                    y: .value("Weight", point.weightKgSnapshot ?? 0)
                                )
                                .foregroundStyle(Theme.accent)
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
                            .frame(height: 180)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Theme.secondaryText)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
    }
}
