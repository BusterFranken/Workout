import SwiftUI

struct WorkoutHeatmapView: View {
    let points: [DayActivityPoint]

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    private let totalWeeks = 52
    private let targetVisibleWeeks = 12
    private let columnSpacing: CGFloat = 4
    private let rowSpacing: CGFloat = 4
    private let weekdayColumnWidth: CGFloat = 14
    private let monthRowHeight: CGFloat = 14
    private let monthRowSpacing: CGFloat = 5
    private let monthLabelWidth: CGFloat = 34

    var body: some View {
        let grid = buildGrid()

        VStack(alignment: .leading, spacing: 10) {
            Text("Workout Days")
                .font(.headline)

            GeometryReader { geometry in
                let availableGridWidth = max(geometry.size.width - weekdayColumnWidth - 8, 120)
                let cellSize = resolvedCellSize(for: availableGridWidth)
                let contentWidth = CGFloat(grid.columns) * cellSize + CGFloat(grid.columns - 1) * columnSpacing

                ScrollViewReader { proxy in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: rowSpacing) {
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                                Text(day)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(width: weekdayColumnWidth, height: cellSize, alignment: .leading)
                            }
                        }
                        .padding(.top, monthRowHeight + monthRowSpacing)

                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: monthRowSpacing) {
                                ZStack(alignment: .leading) {
                                    ForEach(grid.monthLabelColumns, id: \.self) { column in
                                        Text(grid.monthLabels[column] ?? "")
                                            .font(.caption2)
                                            .foregroundStyle(Theme.secondaryText)
                                            .lineLimit(1)
                                            .frame(width: monthLabelWidth, alignment: .leading)
                                            .offset(x: xOffset(for: column, cellSize: cellSize))
                                    }
                                }
                                .frame(width: contentWidth, height: monthRowHeight, alignment: .leading)

                                HStack(spacing: columnSpacing) {
                                    ForEach(0..<grid.columns, id: \.self) { column in
                                        VStack(spacing: rowSpacing) {
                                            ForEach(0..<7, id: \.self) { row in
                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .fill(color(for: grid.values[column][row]))
                                                    .frame(width: cellSize, height: cellSize)
                                            }
                                        }
                                        .id(column)
                                    }
                                }
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(grid.columns - 1, anchor: .trailing)
                        }
                    }
                }
            }
            .frame(height: monthRowHeight + monthRowSpacing + (7 * 16) + (6 * rowSpacing))

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

    private func xOffset(for column: Int, cellSize: CGFloat) -> CGFloat {
        CGFloat(column) * (cellSize + columnSpacing)
    }

    private func resolvedCellSize(for availableGridWidth: CGFloat) -> CGFloat {
        let totalSpacing = CGFloat(max(targetVisibleWeeks - 1, 0)) * columnSpacing
        let raw = (availableGridWidth - totalSpacing) / CGFloat(targetVisibleWeeks)
        return min(max(raw, 10), 16)
    }

    private func buildGrid() -> HeatmapGrid {
        let calendar = Calendar.workout
        let today = Date().startOfDayDate()
        let endWeek = today.startOfWorkoutWeek()
        let startWeek = calendar.date(byAdding: .weekOfYear, value: -(totalWeeks - 1), to: endWeek) ?? endWeek

        var sessionsByDay: [Date: Int] = [:]
        for point in points {
            sessionsByDay[point.date.startOfDayDate()] = point.sessions
        }

        var values = Array(repeating: Array(repeating: 0, count: 7), count: totalWeeks)
        var monthLabels: [Int: String] = [:]
        var monthLabelColumns: [Int] = []

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var previousMonth: Int?
        for column in 0..<totalWeeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: column, to: startWeek) else { continue }
            let month = calendar.component(.month, from: weekStart)
            if previousMonth == nil || previousMonth != month {
                monthLabels[column] = monthFormatter.string(from: weekStart)
                monthLabelColumns.append(column)
                previousMonth = month
            }

            for row in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: row, to: weekStart)?.startOfDayDate() else { continue }
                values[column][row] = sessionsByDay[date] ?? 0
            }
        }

        return HeatmapGrid(
            columns: totalWeeks,
            values: values,
            monthLabels: monthLabels,
            monthLabelColumns: monthLabelColumns
        )
    }
}

private struct HeatmapGrid {
    let columns: Int
    let values: [[Int]]
    let monthLabels: [Int: String]
    let monthLabelColumns: [Int]
}
