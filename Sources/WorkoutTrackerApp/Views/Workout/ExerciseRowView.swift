import SwiftUI
import UniformTypeIdentifiers

struct ExerciseRowView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let exercise: WeeklyExerciseEntity
    let isReordering: Bool
    let isActiveDragItem: Bool
    let activeDragExerciseID: UUID?
    let rowIndex: Int
    let onOpenEditor: () -> Void
    let onOpenDetail: () -> Void
    let onDelete: () -> Void
    let onMarkDone: () -> Void
    let onStartDrag: (UUID) -> Void
    let onDropAtIndex: (UUID, Int) -> Void
    @Binding var hoveredInsertionIndex: Int?

    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var didTriggerThresholdHaptic = false
    @State private var dragIntent: RowDragIntent = .undetermined
    @FocusState private var focusedMetric: RowMetricField?

    private let trailingRevealWidth: CGFloat = 134
    private let rowHeight: CGFloat = 56
    private let swipeActivationDistance: CGFloat = 20


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
        .frame(height: rowHeight)
        .padding(.vertical, 2)
        .onDrag {
            onStartDrag(exercise.id)
            return NSItemProvider(object: exercise.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.plainText],
            delegate: RowDropDelegate(
                rowHeight: rowHeight,
                rowIndex: rowIndex,
                targetExercise: exercise,
                activeDragExerciseID: activeDragExerciseID,
                hoveredInsertionIndex: $hoveredInsertionIndex,
                onDropAtIndex: onDropAtIndex
            )
        )
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
                    if focusedMetric != nil {
                        focusedMetric = nil
                        return
                    }
                    guard !isReordering else { return }
                    if baseOffset < 0 {
                        withAnimation(.spring) { baseOffset = 0 }
                    } else {
                        onOpenDetail()
                    }
                }

            MetricBubble(
                text: setsBinding,
                suffix: "s",
                focusedMetric: $focusedMetric,
                focusField: .sets,
                isEditable: !isReordering
            )
            MetricBubble(
                text: repsOrSecondsBinding,
                suffix: "r",
                minCharacterCount: 2,
                focusedMetric: $focusedMetric,
                focusField: .reps,
                isEditable: !isReordering
            )
            MetricBubble(
                text: weightBinding,
                placeholder: "BW",
                suffix: "kg",
                minCharacterCount: 3,
                focusedMetric: $focusedMetric,
                focusField: .weight,
                isEditable: !isReordering
            )
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
        .scaleEffect(isActiveDragItem ? 1.02 : 1)
        .shadow(
            color: Theme.shadow.opacity(isActiveDragItem ? 0.9 : 0),
            radius: isActiveDragItem ? 12 : 0,
            y: isActiveDragItem ? 6 : 0
        )
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: isActiveDragItem)
        .contentShape(Rectangle())
        .onTapGesture {
            if focusedMetric != nil {
                focusedMetric = nil
            }
        }
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: swipeActivationDistance, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                guard !isReordering else {
                    state = 0
                    return
                }
                guard dragIntent == .horizontal else {
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
                defer {
                    dragIntent = .undetermined
                    didTriggerThresholdHaptic = false
                }
                guard !isReordering else {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                        baseOffset = 0
                    }
                    return
                }
                guard dragIntent == .horizontal else { return }
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
                    dragIntent = .undetermined
                    didTriggerThresholdHaptic = false
                    return
                }
                if dragIntent == .undetermined {
                    dragIntent = resolvedDragIntent(for: value.translation)
                }
                guard dragIntent == .horizontal else {
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

    private func resolvedDragIntent(for translation: CGSize) -> RowDragIntent {
        let x = abs(translation.width)
        let y = abs(translation.height)
        guard max(x, y) >= swipeActivationDistance else { return .undetermined }
        if x > y * 1.15 {
            return .horizontal
        }
        if y > x * 1.15 {
            return .vertical
        }
        return .undetermined
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

private enum RowDragIntent {
    case undetermined
    case horizontal
    case vertical
}

private enum RowMetricField: Hashable {
    case sets
    case reps
    case weight
}

private struct RowDropDelegate: DropDelegate {
    let rowHeight: CGFloat
    let rowIndex: Int
    let targetExercise: WeeklyExerciseEntity
    let activeDragExerciseID: UUID?
    @Binding var hoveredInsertionIndex: Int?
    let onDropAtIndex: (UUID, Int) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        guard let sourceID = activeDragExerciseID else { return false }
        return sourceID != targetExercise.id
    }

    func dropEntered(info: DropInfo) {
        updateDropState(for: info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateDropState(for: info)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        hoveredInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { hoveredInsertionIndex = nil }

        guard let sourceID = activeDragExerciseID, sourceID != targetExercise.id else {
            return false
        }

        let insertionIndex = hoveredInsertionIndex ?? index(for: info.location)
        onDropAtIndex(sourceID, insertionIndex)
        return true
    }

    private func updateDropState(for info: DropInfo) {
        guard validateDrop(info: info) else {
            hoveredInsertionIndex = nil
            return
        }

        hoveredInsertionIndex = index(for: info.location)
    }

    private func index(for location: CGPoint) -> Int {
        location.y >= rowHeight * 0.5 ? rowIndex + 1 : rowIndex
    }
}

private struct MetricBubble: View {
    @Binding var text: String
    var placeholder: String = ""
    var suffix: String = ""
    var minCharacterCount: Int = 1
    var focusedMetric: FocusState<RowMetricField?>.Binding
    var focusField: RowMetricField
    var isEditable: Bool = true

    @State private var localText: String = ""

    private var isFocused: Bool {
        focusedMetric.wrappedValue == focusField
    }

    private var fieldWidth: CGFloat {
        let displayText = isFocused ? localText : text
        let characterCount = max(max(displayText.count, placeholder.count), max(minCharacterCount, 1))
        let ideal = CGFloat(characterCount) * 8 + 2
        return min(max(ideal, 12), 50)
    }

    var body: some View {
        HStack(spacing: 0) {
            TextField(placeholder, text: $localText)
                .numbersAndPunctuationKeyboardIfAvailable()
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: fieldWidth)
                .focused(focusedMetric, equals: focusField)
                .disabled(!isEditable)

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.mutedSurface)
        )
        .onAppear { localText = text }
        .onChange(of: text) { _, newValue in
            if !isFocused { localText = newValue }
        }
        .onChange(of: focusedMetric.wrappedValue) { _, newFocus in
            if newFocus == focusField {
                localText = text
            } else if localText != text {
                text = localText
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func numbersAndPunctuationKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }
}
