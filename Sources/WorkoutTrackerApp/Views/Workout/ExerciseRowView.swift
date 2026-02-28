import SwiftUI

struct ExerciseRowView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity
    let isReordering: Bool
    let onOpenEditor: () -> Void
    let onOpenDetail: () -> Void
    let onStartDrag: (UUID) -> Void
    let onDropOnRow: (UUID, WeeklyExerciseEntity) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                repository.toggleExerciseCompleted(exercise)
            } label: {
                Image(systemName: exercise.completedAt == nil ? "square" : "checkmark.square.fill")
                    .font(.title3)
                    .foregroundStyle(exercise.completedAt == nil ? Theme.secondaryText : Theme.accent)
            }
            .buttonStyle(.plain)

            Text(exercise.name.isEmpty ? "New exercise" : exercise.name)
                .font(.rowBody)
                .foregroundStyle(exercise.name.isEmpty ? Theme.secondaryText : Theme.primaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            MetricField(label: "st", text: setsBinding, width: 44)
            MetricField(label: exercise.seconds != nil && exercise.reps == nil ? "s" : "rp", text: repsOrSecondsBinding, width: 44)
            MetricField(label: "kg", text: weightBinding, width: 54, placeholder: "BW")

            if let count = exercise.weightCount, count > 1 {
                Text("x\(count)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 24)
            }

            Button(action: onOpenEditor) {
                Image(systemName: "pencil")
                    .foregroundStyle(Theme.secondaryText)
            }
            .buttonStyle(.plain)

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Theme.secondaryText.opacity(isReordering ? 1 : 0.35))
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenDetail)
        .wiggle(isReordering)
        .draggable(exercise.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first,
                  let sourceID = UUID(uuidString: first),
                  sourceID != exercise.id else {
                return false
            }
            onDropOnRow(sourceID, exercise)
            return true
        }
        .onLongPressGesture {
            onStartDrag(exercise.id)
        }
    }

    private var setsBinding: Binding<String> {
        Binding(
            get: { exercise.sets.map(String.init) ?? "" },
            set: {
                exercise.sets = Int($0.filter { $0.isNumber })
                repository.updateExercise(exercise)
            }
        )
    }

    private var repsOrSecondsBinding: Binding<String> {
        Binding(
            get: {
                if exercise.seconds != nil && exercise.reps == nil {
                    return exercise.seconds.map(String.init) ?? ""
                }
                return exercise.reps.map(String.init) ?? ""
            },
            set: {
                let value = Int($0.filter { $0.isNumber })
                if exercise.seconds != nil && exercise.reps == nil {
                    exercise.seconds = value
                } else {
                    exercise.reps = value
                }
                repository.updateExercise(exercise)
            }
        )
    }

    private var weightBinding: Binding<String> {
        Binding(
            get: {
                guard let kg = exercise.weightKg else { return "" }
                return kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
            },
            set: {
                let cleaned = $0
                    .lowercased()
                    .replacingOccurrences(of: "kg", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if cleaned.isEmpty || cleaned == "bw" {
                    exercise.weightKg = nil
                    exercise.weightCount = nil
                    repository.updateExercise(exercise)
                    return
                }

                exercise.weightKg = Double(cleaned)
                repository.updateExercise(exercise)
            }
        )
    }
}

private struct MetricField: View {
    let label: String
    @Binding var text: String
    let width: CGFloat
    var placeholder: String = ""

    var body: some View {
        HStack(spacing: 2) {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: width)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.mutedSurface)
                )

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
