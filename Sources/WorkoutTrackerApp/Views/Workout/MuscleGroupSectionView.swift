import SwiftUI
import UniformTypeIdentifiers

struct MuscleGroupSectionView: View {
    let section: WorkoutSectionModel
    let isReordering: Bool
    let activeDragExerciseID: UUID?
    let onRenameSection: () -> Void
    let onAddExercise: () -> Void
    let onRowEdit: (WeeklyExerciseEntity) -> Void
    let onRowDetail: (WeeklyExerciseEntity) -> Void
    let onRowDelete: (WeeklyExerciseEntity) -> Void
    let onMarkDone: (WeeklyExerciseEntity) -> Void
    let onDragStart: (UUID) -> Void
    let onDropOnSection: (UUID, String) -> Void
    let onDropOnRow: (UUID, WeeklyExerciseEntity, Bool) -> Void

    @State private var isSectionDropTargeted = false
    @State private var hoveredInsertionIndex: Int?

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

            if let subtitle = section.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
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
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                        VStack(spacing: 0) {
                            if hoveredInsertionIndex == index {
                                insertionLine
                            }

                            ExerciseRowView(
                                exercise: row,
                                isReordering: isReordering,
                                isActiveDragItem: activeDragExerciseID == row.id,
                                activeDragExerciseID: activeDragExerciseID,
                                rowIndex: index,
                                onOpenEditor: { onRowEdit(row) },
                                onOpenDetail: { onRowDetail(row) },
                                onDelete: { onRowDelete(row) },
                                onMarkDone: { onMarkDone(row) },
                                onStartDrag: onDragStart,
                                onDropAtIndex: { sourceID, insertionIndex in
                                    onDropOnRow(sourceID, row, insertionIndex > index)
                                },
                                hoveredInsertionIndex: $hoveredInsertionIndex
                            )
                        }
                    }

                    if hoveredInsertionIndex == section.rows.count {
                        insertionLine
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard(cornerRadius: 18)
        .overlay(alignment: .bottom) {
            if section.rows.isEmpty && isSectionDropTargeted {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(height: 2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .onDrop(
            of: [UTType.plainText],
            delegate: SectionDropDelegate(
                sectionID: section.id,
                activeDragExerciseID: activeDragExerciseID,
                isSectionDropTargeted: $isSectionDropTargeted,
                hoveredInsertionIndex: $hoveredInsertionIndex,
                totalRows: section.rows.count,
                onDropOnSection: onDropOnSection
            )
        )
    }

    private var insertionLine: some View {
        Rectangle()
            .fill(Theme.accent)
            .frame(height: 2)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
    }
}

private struct SectionDropDelegate: DropDelegate {
    let sectionID: String
    let activeDragExerciseID: UUID?
    @Binding var isSectionDropTargeted: Bool
    @Binding var hoveredInsertionIndex: Int?
    let totalRows: Int
    let onDropOnSection: (UUID, String) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        activeDragExerciseID != nil
    }

    func dropEntered(info: DropInfo) {
        isSectionDropTargeted = validateDrop(info: info)
        if isSectionDropTargeted {
            hoveredInsertionIndex = totalRows
        }
    }

    func dropExited(info: DropInfo) {
        isSectionDropTargeted = false
        hoveredInsertionIndex = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        isSectionDropTargeted = validateDrop(info: info)
        if isSectionDropTargeted {
            hoveredInsertionIndex = totalRows
        }
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            isSectionDropTargeted = false
            hoveredInsertionIndex = nil
        }

        guard let sourceID = activeDragExerciseID else {
            return false
        }

        onDropOnSection(sourceID, sectionID)
        return true
    }
}
