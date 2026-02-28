import SwiftUI

struct MuscleGroupSectionView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let group: MuscleGroupEntity
    let rows: [WeeklyExerciseEntity]
    let doneCount: Int
    let isReordering: Bool
    let onRename: () -> Void
    let onAddExercise: () -> Void
    let onRowEdit: (WeeklyExerciseEntity) -> Void
    let onRowDetail: (WeeklyExerciseEntity) -> Void
    let onDragStart: (UUID) -> Void
    let onDropOnGroup: (UUID, UUID) -> Void
    let onDropOnRow: (UUID, WeeklyExerciseEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(group.name)
                    .font(.title3.weight(.bold))

                Text("\(doneCount)")
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.mutedSurface))

                Spacer()

                Button(action: onAddExercise) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)

                Button(action: onRename) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.primaryText)
            .dropDestination(for: String.self) { items, _ in
                guard let first = items.first,
                      let sourceID = UUID(uuidString: first)
                else {
                    return false
                }
                onDropOnGroup(sourceID, group.id)
                return true
            }

            if rows.isEmpty {
                Text("No exercises yet")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 4)
            } else {
                ForEach(rows) { row in
                    ExerciseRowView(
                        exercise: row,
                        isReordering: isReordering,
                        onOpenEditor: { onRowEdit(row) },
                        onOpenDetail: { onRowDetail(row) },
                        onStartDrag: onDragStart,
                        onDropOnRow: onDropOnRow
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            repository.removeExerciseFromWeek(row)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
    }
}
