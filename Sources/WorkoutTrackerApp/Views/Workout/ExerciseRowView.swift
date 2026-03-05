import SwiftUI

struct ExerciseRowView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity
    let isReordering: Bool
    let onOpenEditor: () -> Void
    let onOpenDetail: () -> Void
    let onDelete: () -> Void
    let onMarkDone: () -> Void
    let onStartDrag: (UUID) -> Void
    let onDropOnRow: (UUID, WeeklyExerciseEntity) -> Void

    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var didTriggerThresholdHaptic = false

    private let trailingRevealWidth: CGFloat = 134

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                swipeBackground

                rowContent
                    .offset(x: totalOffset)
                    .simultaneousGesture(dragGesture(width: proxy.size.width))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: totalOffset)
            .scaleEffect(totalOffset > 0 ? 0.995 : 1.0)
        }
        .frame(height: 56)
        .padding(.vertical, 2)
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

    private var totalOffset: CGFloat {
        baseOffset + dragOffset
    }

    private var swipeBackground: some View {
        ZStack {
            if totalOffset > 0 {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent.opacity(0.16))

                HStack {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.leading, 14)
                    Spacer()
                }
            }

            if totalOffset < 0 {
                HStack(spacing: 0) {
                    Spacer()

                    Button {
                        withAnimation(.spring) {
                            baseOffset = 0
                        }
                        Haptics.selection()
                        onOpenEditor()
                    } label: {
                        VStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: trailingRevealWidth / 2)
                        .frame(maxHeight: .infinity)
                        .background(Color.blue)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring) {
                            baseOffset = 0
                        }
                        Haptics.warning()
                        onDelete()
                    } label: {
                        VStack {
                            Image(systemName: "trash")
                            Text("Delete")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: trailingRevealWidth / 2)
                        .frame(maxHeight: .infinity)
                        .background(Theme.warning)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            Text(exercise.name.isEmpty ? "New exercise" : exercise.name)
                .font(.rowBody)
                .foregroundStyle(exercise.name.isEmpty ? Theme.secondaryText : Theme.primaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    guard !isReordering else { return }
                    if baseOffset < 0 {
                        withAnimation(.spring) { baseOffset = 0 }
                    } else {
                        onOpenDetail()
                    }
                }

            MetricBubble(label: "st", text: setsBinding, width: 52, isEditable: !isReordering)
            MetricBubble(
                label: exercise.seconds != nil && exercise.reps == nil ? "s" : "rp",
                text: repsOrSecondsBinding,
                width: 52,
                isEditable: !isReordering
            )
            MetricBubble(
                label: Formatting.weightPlaceholder(for: repository.unitSystem),
                text: weightBinding,
                width: 58,
                placeholder: "BW",
                isEditable: !isReordering
            )

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Theme.secondaryText.opacity(isReordering ? 1 : 0.35))
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.primaryText.opacity(0.06), lineWidth: 1)
        )
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                guard !isReordering else {
                    state = 0
                    return
                }
                let x = value.translation.width
                if x > 0 {
                    state = min(x, width * 0.72)
                } else {
                    state = max(x, -trailingRevealWidth)
                }
            }
            .onEnded { value in
                guard !isReordering else {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                        baseOffset = 0
                    }
                    return
                }
                let x = value.translation.width

                if x > width * 0.34 {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                        baseOffset = width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        baseOffset = 0
                        Haptics.success()
                        onMarkDone()
                    }
                    return
                }

                if x < -70 {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                        baseOffset = -trailingRevealWidth
                    }
                    return
                }

                withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                    baseOffset = 0
                }
            }
            .onChanged { value in
                guard !isReordering else {
                    didTriggerThresholdHaptic = false
                    return
                }
                let x = value.translation.width
                let crossed = x > width * 0.34
                if crossed && !didTriggerThresholdHaptic {
                    didTriggerThresholdHaptic = true
                    Haptics.soft()
                } else if !crossed {
                    didTriggerThresholdHaptic = false
                }
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
                switch repository.unitSystem {
                case .kg:
                    return kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
                case .lb:
                    let lb = kg * 2.2046226218
                    return lb.rounded() == lb ? String(Int(lb)) : String(format: "%.1f", lb)
                }
            },
            set: {
                exercise.weightKg = Formatting.parseWeightEntry($0, unit: repository.unitSystem)
                repository.updateExercise(exercise)
            }
        )
    }
}

private struct MetricBubble: View {
    let label: String
    @Binding var text: String
    let width: CGFloat
    var placeholder: String = ""
    var isEditable: Bool = true

    var body: some View {
        HStack(spacing: 1) {
            TextField(placeholder, text: $text)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: width)
                .disabled(!isEditable)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.mutedSurface)
        )
    }
}
