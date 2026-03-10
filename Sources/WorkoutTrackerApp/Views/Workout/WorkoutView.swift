import SwiftUI
#if os(iOS)
import UIKit
#endif

struct WorkoutView: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @EnvironmentObject private var navigation: AppNavigationState

    @State private var isGoalEditMode = false
    @State private var isExerciseReorderMode = false
    @State private var activeDragExerciseID: UUID?

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

                    if repository.workoutSections.isEmpty && repository.activeWeeklyExercises.isEmpty {
                        emptyStateCard
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(repository.workoutSections) { section in
                                MuscleGroupSectionView(
                                    section: section,
                                    isReordering: isExerciseReorderMode,
                                    activeDragExerciseID: activeDragExerciseID,
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
                .contentShape(Rectangle())
                .padding()
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
            .onTapGesture {
                dismissKeyboard()
                if isGoalEditMode {
                    isGoalEditMode = false
                }
                if isExerciseReorderMode {
                    endExerciseReorderMode()
                }
            }
        }
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
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
                    Button {
                        repository.toggleExerciseCompleted(row)
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)

                            Text(row.name)
                                .strikethrough()
                                .foregroundStyle(Theme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(row.sets ?? 0) st")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
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

private struct RenameHeaderSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let header: SectionHeaderEntity
    @Binding var isPresented: Bool

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Header name", text: $name)
            }
            .navigationTitle("Rename Header")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.renameHeader(header, to: name)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear { name = header.title }
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
