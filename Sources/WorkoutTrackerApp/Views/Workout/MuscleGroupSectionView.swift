import SwiftUI

struct MuscleGroupSectionView: View {
    let section: WorkoutSectionModel
    let isReordering: Bool
    let onRenameSection: () -> Void
    let onAddExercise: () -> Void
    let onRowEdit: (WeeklyExerciseEntity) -> Void
    let onRowDetail: (WeeklyExerciseEntity) -> Void
    let onRowDelete: (WeeklyExerciseEntity) -> Void
    let onMarkDone: (WeeklyExerciseEntity) -> Void
    let onDragStart: (UUID) -> Void
    let onDropOnSection: (UUID, String) -> Void
    let onDropOnRow: (UUID, WeeklyExerciseEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(section.title)
                    .font(.title3.weight(.bold))

                Text("\(section.doneCount)")
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.mutedSurface))

                Spacer()

                Button(action: onAddExercise) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)

                if section.sectionHeader != nil {
                    Button(action: onRenameSection) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundStyle(Theme.primaryText)

            Group {
                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let first = items.first,
                      let sourceID = UUID(uuidString: first)
                else {
                    return false
                }
                onDropOnSection(sourceID, section.id)
                return true
            }

            if section.rows.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.subtitle == "Rest" ? "Rest day" : "No exercises yet")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)

                    Text("Drop an exercise here")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText.opacity(0.85))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.secondaryText.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                )
                .dropDestination(for: String.self) { items, _ in
                    guard let first = items.first,
                          let sourceID = UUID(uuidString: first)
                    else {
                        return false
                    }
                    onDropOnSection(sourceID, section.id)
                    return true
                }
            } else {
                ForEach(section.rows) { row in
                    ExerciseRowView(
                        exercise: row,
                        isReordering: isReordering,
                        onOpenEditor: { onRowEdit(row) },
                        onOpenDetail: { onRowDetail(row) },
                        onDelete: { onRowDelete(row) },
                        onMarkDone: { onMarkDone(row) },
                        onStartDrag: onDragStart,
                        onDropOnRow: onDropOnRow
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard(cornerRadius: 18)
    }
}
