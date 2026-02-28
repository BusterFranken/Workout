import Charts
import SwiftUI

struct TrackingView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @State private var expandedGroups: Set<UUID> = []
    @State private var selectedExercise: WeeklyExerciseEntity?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights & Analytics")
                        .font(.sectionTitle)

                    weeklySetsCard
                    WorkoutHeatmapView(points: repository.last30DayActivity())
                    muscleVolumeCard
                    prCard
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Tracking")
            .sheet(item: $selectedExercise) { row in
                ExerciseDetailSheet(exercise: row)
            }
        }
    }

    private var weeklySetsCard: some View {
        let points = repository.weeklySetTrend(weeks: 8)

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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
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
                    ForEach(item.exercises) { exercise in
                        Button {
                            selectedExercise = exercise
                        } label: {
                            HStack {
                                Text(exercise.name.isEmpty ? "Untitled Exercise" : exercise.name)
                                Spacer()
                                Text("\(exercise.sets ?? 0) st")
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private var prCard: some View {
        let prs = repository.classicPRs()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Classic PR Tracking")
                .font(.headline)

            ForEach(prs) { pr in
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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }
}
