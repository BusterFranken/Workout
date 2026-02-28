import SwiftUI

struct WorkoutHeatmapView: View {
    let points: [DayActivityPoint]

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let grid = buildGrid()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workout Days (Last 30)")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(height: 14)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<grid.columns, id: \.self) { column in
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { row in
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(color(for: grid.values[column][row]))
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private func color(for value: Int) -> Color {
        switch value {
        case 0:
            return Theme.mutedSurface
        case 1:
            return Theme.accent.opacity(0.35)
        case 2:
            return Theme.accent.opacity(0.6)
        default:
            return Theme.accent
        }
    }

    private func buildGrid() -> (columns: Int, values: [[Int]]) {
        guard let first = points.first else {
            return (columns: 5, values: Array(repeating: Array(repeating: 0, count: 7), count: 5))
        }

        let calendar = Calendar.workout
        let startWeek = first.date.startOfWorkoutWeek()

        var map: [Int: [Int: Int]] = [:]
        var maxColumn = 0

        for point in points {
            let weekOffset = calendar.dateComponents([.weekOfYear], from: startWeek, to: point.date).weekOfYear ?? 0
            let weekday = ((calendar.component(.weekday, from: point.date) + 5) % 7)
            map[weekOffset, default: [:]][weekday] = point.sessions
            maxColumn = max(maxColumn, weekOffset)
        }

        let columns = max(maxColumn + 1, 5)
        var matrix = Array(repeating: Array(repeating: 0, count: 7), count: columns)

        for (col, rows) in map {
            guard col >= 0, col < columns else { continue }
            for (row, value) in rows where row >= 0 && row < 7 {
                matrix[col][row] = value
            }
        }

        return (columns: columns, values: matrix)
    }
}
