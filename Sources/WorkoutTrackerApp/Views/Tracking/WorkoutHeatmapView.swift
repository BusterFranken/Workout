import SwiftUI

struct WorkoutHeatmapView: View {
    let points: [DayActivityPoint]

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let grid = buildGrid()

        VStack(alignment: .leading, spacing: 10) {
            Text("Workout Days")
                .font(.headline)

            ScrollViewReader { proxy in
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
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 4) {
                                ForEach(0..<grid.columns, id: \.self) { column in
                                    Text(grid.monthLabels[column] ?? "")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.secondaryText)
                                        .frame(width: 16, alignment: .leading)
                                }
                            }

                            HStack(spacing: 4) {
                                ForEach(0..<grid.columns, id: \.self) { column in
                                    VStack(spacing: 4) {
                                        ForEach(0..<7, id: \.self) { row in
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .fill(color(for: grid.values[column][row]))
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                    .id(column)
                                }
                            }
                        }
                    }
                    .onAppear {
                        if grid.columns > 0 {
                            proxy.scrollTo(grid.columns - 1, anchor: .trailing)
                        }
                    }
                }
            }

            Text("Swipe to view older workout history")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard()
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

    private func buildGrid() -> (columns: Int, values: [[Int]], monthLabels: [Int: String]) {
        guard let first = points.first else {
            return (columns: 6, values: Array(repeating: Array(repeating: 0, count: 7), count: 6), monthLabels: [:])
        }

        let calendar = Calendar.workout
        let startWeek = first.date.startOfWorkoutWeek()

        var map: [Int: [Int: Int]] = [:]
        var monthLabels: [Int: String] = [:]
        var maxColumn = 0

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        for point in points {
            let weekOffset = calendar.dateComponents([.weekOfYear], from: startWeek, to: point.date).weekOfYear ?? 0
            let weekday = ((calendar.component(.weekday, from: point.date) + 5) % 7)
            map[weekOffset, default: [:]][weekday] = point.sessions
            maxColumn = max(maxColumn, weekOffset)

            if calendar.component(.day, from: point.date) <= 7 {
                monthLabels[weekOffset] = monthFormatter.string(from: point.date)
            }
        }

        let columns = max(maxColumn + 1, 6)
        var matrix = Array(repeating: Array(repeating: 0, count: 7), count: columns)

        for (column, rows) in map {
            guard column >= 0, column < columns else { continue }
            for (row, value) in rows where row >= 0 && row < 7 {
                matrix[column][row] = value
            }
        }

        return (columns: columns, values: matrix, monthLabels: monthLabels)
    }
}
