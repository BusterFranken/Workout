import SwiftUI
#if os(iOS)
import UIKit
#endif
import UniformTypeIdentifiers

struct WorkoutView: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @EnvironmentObject private var navigation: AppNavigationState

    @State private var isGoalEditMode = false
    @State private var isExerciseReorderMode = false
    @State private var isSectionReorderMode = false
    @State private var activeDragExerciseID: UUID?
    @State private var activeDragSectionID: UUID?
    @State private var hoveredSectionInsertionIndex: Int?

    @State private var showingNewWeekWarning = false
    @State private var showingDeleteDialog = false
    @State private var showingSaveSheet = false
    @State private var showingAddGroupSheet = false
    @State private var showingSetGoalEditor = false
    @State private var showingWorkoutNameEditor = false

    @State private var newTemplateName = ""
    @State private var newGroupName = ""
    @State private var editedWorkoutName = ""

    @State private var selectedExerciseForEditor: WeeklyExerciseEntity?
    @State private var selectedExerciseForDetails: WeeklyExerciseEntity?
    @State private var selectedHeaderForRename: SectionHeaderEntity?

    @State private var showDoneSection = true
    @State private var pendingDeleteAfterSave = false
    @State private var pendingNewExerciseID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    GoalCardStripView(
                        isEditing: $isGoalEditMode,
                        showingTargetEditor: $showingSetGoalEditor
                    )
                    .onLongPressGesture {
                        withAnimation(.spring) {
                            isGoalEditMode.toggle()
                        }
                    }

                    if repository.showSuggestedWorkout {
                        SuggestedWorkoutView(
                            onRowEdit: { selectedExerciseForEditor = $0 },
                            onRowDetail: { selectedExerciseForDetails = $0 },
                            onRowDelete: { repository.removeExerciseFromWeek($0) },
                            onMarkDone: { exercise in
                                repository.toggleExerciseCompleted(exercise)
                                Haptics.selection()
                            }
                        )
                    }

                    if repository.workoutSections.isEmpty && repository.activeWeeklyExercises.isEmpty {
                        emptyStateCard
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(repository.workoutSections.enumerated()), id: \.element.id) { index, section in
                                if repository.workoutViewMode == .muscleGroups && isSectionReorderMode {
                                    sectionInsertionDropZone(at: index)
                                }

                                MuscleGroupSectionView(
                                    section: section,
                                    isCollapsed: repository.isSectionCollapsed(section.id),
                                    isReordering: isExerciseReorderMode || isSectionReorderMode,
                                    activeDragExerciseID: activeDragExerciseID,
                                    onToggleCollapse: {
                                        repository.toggleSectionCollapsed(section.id)
                                    },
                                    onRenameSection: {
                                        if let header = section.sectionHeader {
                                            selectedHeaderForRename = header
                                        }
                                    },
                                    onAddExercise: {
                                        let row = repository.addExercise(to: section)
                                        pendingNewExerciseID = row.id
                                        selectedExerciseForEditor = row
                                    },
                                    onRowEdit: { row in
                                        selectedExerciseForEditor = row
                                    },
                                    onRowDetail: { row in
                                        selectedExerciseForDetails = row
                                    },
                                    onRowDelete: { row in
                                        repository.removeExerciseFromWeek(row)
                                    },
                                    onMarkDone: { row in
                                        repository.toggleExerciseCompleted(row)
                                    },
                                    onDragStart: { sourceID in
                                        withAnimation(.spring) {
                                            activeDragExerciseID = sourceID
                                        }
                                        Haptics.soft()
                                    },
                                    onDropOnSection: { sourceID, sectionID in
                                        moveExercise(sourceID: sourceID, toSectionID: sectionID, targetIndex: nil)
                                        endExerciseReorderMode()
                                    },
                                    onDropOnRow: { sourceID, targetRow, insertAfter in
                                        let target = max(0, targetRow.orderIndex + (insertAfter ? 1 : 0))
                                        moveExercise(sourceID: sourceID, toSectionID: section.id, targetIndex: target)
                                        endExerciseReorderMode()
                                    }
                                )
                                .if(
                                    repository.workoutViewMode == .muscleGroups
                                    && section.sectionHeader != nil
                                ) { view in
                                    view.onDrag {
                                        withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                                            isSectionReorderMode = true
                                            activeDragSectionID = UUID(uuidString: section.id)
                                        }
                                        Haptics.soft()
                                        return NSItemProvider(object: section.id as NSString)
                                    }
                                    .overlay {
                                        if isSectionReorderMode {
                                            GeometryReader { proxy in
                                                Color.clear
                                                    .contentShape(Rectangle())
                                                    .onDrop(
                                                        of: [UTType.plainText],
                                                        delegate: WorkoutSectionCardDropDelegate(
                                                            index: index,
                                                            cardHeight: proxy.size.height,
                                                            activeDragSectionID: $activeDragSectionID,
                                                            hoveredSectionInsertionIndex: $hoveredSectionInsertionIndex,
                                                            isSectionReorderMode: $isSectionReorderMode,
                                                            onReorder: { source, destination in
                                                                repository.reorderWorkoutSections(from: source, to: destination)
                                                            }
                                                        )
                                                    )
                                            }
                                        }
                                    }
                                }
                            }

                            if repository.workoutViewMode == .muscleGroups && isSectionReorderMode {
                                sectionInsertionDropZone(at: repository.workoutSections.count)
                            }

                            if isSectionReorderMode {
                                Text("Drag headers to reorder")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }

                            if repository.shouldShowAddHeadingHint {
                                Button {
                                    repository.addHeadingForCurrentView()
                                    Haptics.selection()
                                } label: {
                                    Label("Add heading", systemImage: "plus")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 8)
                                }
                            }

                        }

                        doneSection
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if isGoalEditMode || isExerciseReorderMode || isSectionReorderMode {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isGoalEditMode { isGoalEditMode = false }
                            if isExerciseReorderMode { endExerciseReorderMode() }
                            if isSectionReorderMode {
                                isSectionReorderMode = false
                                activeDragSectionID = nil
                                hoveredSectionInsertionIndex = nil
                            }
                        }
                }
            }
            .background(Theme.background)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    menu
                }
                #else
                ToolbarItem(placement: .automatic) {
                    menu
                }
                #endif
            }
            .sheet(item: $selectedExerciseForEditor) { row in
                ExerciseEditorSheet(
                    isPresented: Binding(
                        get: { selectedExerciseForEditor != nil },
                        set: { newValue in if !newValue { selectedExerciseForEditor = nil } }
                    ),
                    exercise: row,
                    isNewExercise: row.id == pendingNewExerciseID,
                    onCancelNew: {
                        if row.id == pendingNewExerciseID {
                            repository.removeExerciseFromWeek(row)
                            pendingNewExerciseID = nil
                        }
                    },
                    onSave: {
                        if row.id == pendingNewExerciseID {
                            pendingNewExerciseID = nil
                        }
                    }
                )
            }
            .sheet(item: $selectedExerciseForDetails) { row in
                ExerciseDetailSheet(exercise: row)
            }
            .sheet(item: $selectedHeaderForRename) { header in
                RenameHeaderSheet(
                    header: header,
                    isPresented: Binding(
                        get: { selectedHeaderForRename != nil },
                        set: { newValue in if !newValue { selectedHeaderForRename = nil } }
                    )
                )
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                addGroupSheet
            }
            .sheet(isPresented: $showingSaveSheet) {
                saveWorkoutSheet
            }
            .sheet(isPresented: $showingSetGoalEditor) {
                SetGoalEditorSheet(
                    value: repository.settings?.weeklySetTarget ?? SeedCatalog.defaultWeeklySetGoal,
                    isPresented: $showingSetGoalEditor
                )
            }
            .sheet(isPresented: $showingWorkoutNameEditor) {
                workoutNameSheet
            }
            .confirmationDialog(
                "Delete weekly workout?",
                isPresented: $showingDeleteDialog,
                titleVisibility: .visible
            ) {
                Button("Save Then Delete", role: .destructive) {
                    newTemplateName = "Backup \(Date().isoShort())"
                    pendingDeleteAfterSave = true
                    showingSaveSheet = true
                }
                Button("Delete Without Saving", role: .destructive) {
                    repository.deleteCurrentWeeklyWorkout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all exercises from this week only. History logs stay available in Tracking.")
            }
            .alert("Start New Week?", isPresented: $showingNewWeekWarning) {
                Button("Start New Week", role: .destructive) {
                    repository.startNewWeek()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will uncheck all exercises and create a clean week while preserving history.")
            }
        }
    }

    private func sectionInsertionDropZone(at index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear.opacity(0.001))

            Rectangle()
                .fill(hoveredSectionInsertionIndex == index ? Theme.accent : .clear)
                .frame(height: hoveredSectionInsertionIndex == index ? 3 : 1)
        }
            .contentShape(Rectangle())
            .frame(height: 14)
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(.dashboardDate)
                .foregroundStyle(Theme.secondaryText)

            Text("WORKOUT")
                .font(.dashboardTitle)
                .tracking(1.0)

            HStack(spacing: 8) {
                Text(repository.activeWorkoutName)
                    .font(.headline)
                Button {
                    editedWorkoutName = repository.activeWorkoutName
                    showingWorkoutNameEditor = true
                    Haptics.selection()
                } label: {
                    Image(systemName: "pencil")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var menu: some View {
        Menu {
            if repository.workoutViewMode == .muscleGroups {
                Button("Add New Header", systemImage: "plus") {
                    showingAddGroupSheet = true
                    Haptics.selection()
                }
            }

            Menu("Change View") {
                ForEach(WorkoutViewMode.allCases) { mode in
                    Button {
                        repository.updateWorkoutViewMode(mode)
                        Haptics.selection()
                    } label: {
                        if repository.workoutViewMode == mode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            }

            Button {
                repository.updateShowSuggestedWorkout(!repository.showSuggestedWorkout)
                Haptics.selection()
            } label: {
                if repository.showSuggestedWorkout {
                    Label("Suggest Today's Workout", systemImage: "checkmark")
                } else {
                    Text("Suggest Today's Workout")
                }
            }

            Button("Save This Workout To Library", systemImage: "square.and.arrow.down") {
                newTemplateName = repository.activeWorkoutName
                showingSaveSheet = true
                Haptics.selection()
            }

            Button("New Week", systemImage: "arrow.clockwise") {
                showingNewWeekWarning = true
                Haptics.selection()
            }

            Divider()

            Button("Delete Weekly Workout", systemImage: "trash", role: .destructive) {
                showingDeleteDialog = true
                Haptics.warning()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No Weekly Workout Yet")
                .font(.title3.weight(.bold))

            Text("Add a template from Library, or start with one editable heading.")
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 10) {
                Button("+ Add workout") {
                    navigation.selectedTab = .library
                }
                .buttonStyle(.borderedProminent)

                Button("Start from scratch") {
                    repository.startFromScratchWorkout()
                    Haptics.success()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
        )
        .appCard(cornerRadius: 18)
    }

    private var doneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut) {
                    showDoneSection.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDoneSection ? "chevron.down" : "chevron.right")
                    Text("Done this week (\(repository.doneExercises.count))")
                        .font(.headline)
                }
                .foregroundStyle(Theme.primaryText)
            }
            .buttonStyle(.plain)

            if showDoneSection {
                ForEach(repository.doneExercises) { row in
                    let isPartial = row.completedAt == nil
                    HStack(spacing: 10) {
                        Image(systemName: isPartial ? "circle.lefthalf.filled" : "checkmark.circle.fill")
                            .foregroundStyle(Theme.accent)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isPartial {
                                    repository.undoLastCompletion(row)
                                } else {
                                    repository.toggleExerciseCompleted(row)
                                }
                                Haptics.selection()
                            }

                        HStack(spacing: 10) {
                            Text(row.name)
                                .if(!isPartial) { $0.strikethrough() }
                                .foregroundStyle(isPartial ? Theme.primaryText : Theme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if row.weeklyTarget > 1 {
                                doneProgressDots(for: row)
                            }

                            if row.category != .cardio {
                                Text("\(row.sets ?? 0) st")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            } else if let dur = row.durationMinutes {
                                Text("\(dur)m")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExerciseForDetails = row
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("View Details") {
                            selectedExerciseForDetails = row
                        }
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
    }

    private var addGroupSheet: some View {
        NavigationStack {
            Form {
                TextField("Header name", text: $newGroupName)
            }
            .navigationTitle("Add New Header")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddGroupSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        repository.addHeader(title: newGroupName)
                        newGroupName = ""
                        showingAddGroupSheet = false
                        Haptics.success()
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var workoutNameSheet: some View {
        NavigationStack {
            Form {
                TextField("Workout name", text: $editedWorkoutName)
            }
            .navigationTitle("Workout Name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingWorkoutNameEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.updateWorkoutName(editedWorkoutName)
                        showingWorkoutNameEditor = false
                        Haptics.success()
                    }
                    .disabled(editedWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var saveWorkoutSheet: some View {
        NavigationStack {
            Form {
                TextField("Workout name", text: $newTemplateName)
            }
            .navigationTitle("Save Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        pendingDeleteAfterSave = false
                        showingSaveSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.saveWorkoutToLibrary(name: newTemplateName)
                        if pendingDeleteAfterSave {
                            repository.deleteCurrentWeeklyWorkout()
                        }
                        pendingDeleteAfterSave = false
                        showingSaveSheet = false
                        Haptics.success()
                    }
                    .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func doneProgressDots(for exercise: WeeklyExerciseEntity) -> some View {
        let done = repository.completionCount(for: exercise)
        let target = exercise.weeklyTarget
        return HStack(spacing: 2) {
            ForEach(0..<target, id: \.self) { i in
                Circle()
                    .fill(i < done ? Theme.accent : Theme.secondaryText.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func moveExercise(sourceID: UUID, toSectionID sectionID: String, targetIndex: Int?) {
        let index = targetIndex ?? repository.workoutSections.first(where: { $0.id == sectionID })?.rows.count ?? 0
        repository.moveExercise(sourceID: sourceID, toSectionID: sectionID, at: index)
    }

    private func endExerciseReorderMode() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            activeDragExerciseID = nil
            isExerciseReorderMode = false
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Transformed: View>(
        _ condition: Bool,
        transform: (Self) -> Transformed
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private struct RenameHeaderSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let header: SectionHeaderEntity
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var weeklyGoal: Int = 0
    @State private var weeklySetGoal: Int = 0
    @State private var showingDeleteWarning = false
    @State private var destinationHeaderID: UUID?

    private var attachedExerciseCount: Int {
        repository.exerciseCountForHeader(header)
    }

    private var otherHeaders: [SectionHeaderEntity] {
        repository.activeWeeklyHeaders
            .filter { $0.id != header.id }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Header name", text: $name)

                Section("Weekly Goal") {
                    Toggle("Set exercise goal", isOn: Binding(
                        get: { weeklyGoal > 0 },
                        set: { weeklyGoal = $0 ? max(weeklyGoal, 1) : 0 }
                    ))
                    if weeklyGoal > 0 {
                        Stepper("\(weeklyGoal) exercises", value: $weeklyGoal, in: 1...50)
                    }

                    Toggle("Set volume goal", isOn: Binding(
                        get: { weeklySetGoal > 0 },
                        set: { weeklySetGoal = $0 ? max(weeklySetGoal, 1) : 0 }
                    ))
                    if weeklySetGoal > 0 {
                        Stepper("\(weeklySetGoal) sets", value: $weeklySetGoal, in: 1...100)
                    }
                }

                Section {
                    Button("Delete Header", role: .destructive) {
                        if attachedExerciseCount > 0 {
                            if destinationHeaderID == nil {
                                destinationHeaderID = otherHeaders.first?.id
                            }
                            showingDeleteWarning = true
                        } else {
                            repository.deleteHeader(header, moveExercisesTo: nil)
                            isPresented = false
                        }
                    }
                }

                if showingDeleteWarning {
                    Section("Move Exercises Before Deleting") {
                        Text("This header has \(attachedExerciseCount) exercise(s), including completed ones. Choose another header to move them to before deleting this header.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)

                        if otherHeaders.isEmpty {
                            Text("Add another header first to move these exercises.")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        } else {
                            Picker("Move to", selection: Binding(
                                get: { destinationHeaderID ?? otherHeaders.first?.id ?? UUID() },
                                set: { destinationHeaderID = $0 }
                            )) {
                                ForEach(otherHeaders) { otherHeader in
                                    Text(otherHeader.title).tag(otherHeader.id)
                                }
                            }

                            Button("Move & Delete Header", role: .destructive) {
                                repository.deleteHeader(header, moveExercisesTo: destinationHeaderID)
                                isPresented = false
                            }
                            .disabled(destinationHeaderID == nil)
                        }
                    }
                }
            }
            .navigationTitle("Rename Header")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.renameHeader(header, to: name)
                        repository.updateHeaderGoal(header, goal: weeklyGoal > 0 ? weeklyGoal : nil)
                        repository.updateHeaderSetGoal(header, setGoal: weeklySetGoal > 0 ? weeklySetGoal : nil)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            name = header.title
            weeklyGoal = header.weeklyGoal ?? 0
            weeklySetGoal = header.weeklySetGoal ?? 0
            destinationHeaderID = otherHeaders.first?.id
        }
    }
}

private struct SetGoalEditorSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @State var value: Int
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $value, in: 1...300) {
                    Text("Weekly set goal: \(value)")
                }
            }
            .navigationTitle("Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.updateWeeklySetGoal(value)
                        isPresented = false
                    }
                }
            }
        }
    }
}

private struct WorkoutSectionCardDropDelegate: DropDelegate {
    let index: Int
    let cardHeight: CGFloat
    @Binding var activeDragSectionID: UUID?
    @Binding var hoveredSectionInsertionIndex: Int?
    @Binding var isSectionReorderMode: Bool
    let onReorder: (UUID, Int) -> Void

    private func insertionIndex(for location: CGPoint) -> Int {
        location.y < (cardHeight * 0.5) ? index : index + 1
    }

    func validateDrop(info: DropInfo) -> Bool {
        activeDragSectionID != nil
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        hoveredSectionInsertionIndex = insertionIndex(for: info.location)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { return DropProposal(operation: .cancel) }
        hoveredSectionInsertionIndex = insertionIndex(for: info.location)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        hoveredSectionInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            hoveredSectionInsertionIndex = nil
            DispatchQueue.main.async {
                isSectionReorderMode = false
                activeDragSectionID = nil
            }
        }
        guard let sourceID = activeDragSectionID else { return false }
        let destination = insertionIndex(for: info.location)
        onReorder(sourceID, destination)
        return true
    }
}
