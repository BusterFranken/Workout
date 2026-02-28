import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @EnvironmentObject private var navigation: AppNavigationState

    @State private var isGoalEditMode = false
    @State private var isExerciseReorderMode = false

    @State private var showingNewWeekWarning = false
    @State private var showingDeleteDialog = false
    @State private var showingSaveSheet = false
    @State private var showingAddGroupSheet = false
    @State private var showingSetGoalEditor = false

    @State private var newTemplateName = ""
    @State private var newGroupName = ""

    @State private var selectedExerciseForEditor: WeeklyExerciseEntity?
    @State private var selectedExerciseForDetails: WeeklyExerciseEntity?
    @State private var selectedGroupForRename: MuscleGroupEntity?

    @State private var showDoneSection = true
    @State private var pendingDeleteAfterSave = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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

                    if repository.activeWeeklyExercises.isEmpty {
                        emptyStateCard
                    } else {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(repository.workoutSections) { section in
                                MuscleGroupSectionView(
                                    group: section.group,
                                    rows: section.pending,
                                    doneCount: repository.doneCountForMuscle(section.group.id),
                                    isReordering: isExerciseReorderMode,
                                    onRename: {
                                        selectedGroupForRename = section.group
                                    },
                                    onAddExercise: {
                                        let row = repository.addExercise(to: section.group)
                                        selectedExerciseForEditor = row
                                    },
                                    onRowEdit: { row in
                                        selectedExerciseForEditor = row
                                    },
                                    onRowDetail: { row in
                                        selectedExerciseForDetails = row
                                    },
                                    onDragStart: { _ in
                                        withAnimation(.spring) {
                                            isExerciseReorderMode = true
                                        }
                                    },
                                    onDropOnGroup: { sourceID, groupID in
                                        moveExercise(sourceID: sourceID, to: groupID)
                                    },
                                    onDropOnRow: { sourceID, targetRow in
                                        moveExercise(sourceID: sourceID, onto: targetRow)
                                    }
                                )
                            }
                        }

                        doneSection
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Muscle Group", systemImage: "plus") {
                            showingAddGroupSheet = true
                        }

                        Button("Save This Workout To Library", systemImage: "square.and.arrow.down") {
                            newTemplateName = "Week of \(Date().isoShort())"
                            showingSaveSheet = true
                        }

                        Button("New Week", systemImage: "arrow.clockwise") {
                            showingNewWeekWarning = true
                        }

                        Divider()

                        Button("Delete Weekly Workout", systemImage: "trash", role: .destructive) {
                            showingDeleteDialog = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
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
            .sheet(item: $selectedExerciseForEditor) { row in
                ExerciseEditorSheet(isPresented: Binding(
                    get: { selectedExerciseForEditor != nil },
                    set: { newValue in if !newValue { selectedExerciseForEditor = nil } }
                ), exercise: row)
            }
            .sheet(item: $selectedExerciseForDetails) { row in
                ExerciseDetailSheet(exercise: row)
            }
            .sheet(item: $selectedGroupForRename) { group in
                RenameGroupSheet(
                    group: group,
                    isPresented: Binding(
                        get: { selectedGroupForRename != nil },
                        set: { newValue in if !newValue { selectedGroupForRename = nil } }
                    )
                )
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                NavigationStack {
                    Form {
                        TextField("Muscle group name", text: $newGroupName)
                    }
                    .navigationTitle("Add Muscle Group")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddGroupSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                repository.addMuscleGroup(name: newGroupName)
                                newGroupName = ""
                                showingAddGroupSheet = false
                            }
                            .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSaveSheet) {
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
                            }
                            .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSetGoalEditor) {
                SetGoalEditorSheet(
                    value: repository.settings?.weeklySetTarget ?? SeedCatalog.defaultWeeklySetGoal,
                    isPresented: $showingSetGoalEditor
                )
            }
            .onTapGesture {
                if isGoalEditMode {
                    isGoalEditMode = false
                }
                if isExerciseReorderMode {
                    isExerciseReorderMode = false
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                .font(.dashboardDate)
                .foregroundStyle(Theme.secondaryText)

            Text("WORKOUT")
                .font(.dashboardTitle)

            if let settings = repository.settings {
                Text("Week of \(settings.activeWeekStartDate.isoShort())")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No Weekly Workout Yet")
                .font(.title3.weight(.bold))

            Text("Start by adding a workout template or a few exercises from your library.")
                .foregroundStyle(Theme.secondaryText)

            Button("+ Add workout or exercises") {
                navigation.selectedTab = .library
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
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
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundStyle(Theme.accent)

                        Text(row.name)
                            .strikethrough()
                            .foregroundStyle(Theme.secondaryText)

                        Spacer()

                        Text("\(row.sets ?? 0) st")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.vertical, 4)
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

    private func moveExercise(sourceID: UUID, to groupID: UUID) {
        guard let source = repository.activeWeeklyExercises.first(where: { $0.id == sourceID }),
              let group = repository.muscleGroups.first(where: { $0.id == groupID })
        else {
            return
        }

        let targetIndex = repository.activeWeeklyExercises
            .filter { $0.muscleGroupID == groupID }
            .count

        repository.moveExercise(source, to: group, at: targetIndex)
    }

    private func moveExercise(sourceID: UUID, onto targetRow: WeeklyExerciseEntity) {
        guard let source = repository.activeWeeklyExercises.first(where: { $0.id == sourceID }),
              let groupID = targetRow.muscleGroupID,
              let group = repository.muscleGroups.first(where: { $0.id == groupID })
        else {
            return
        }

        repository.moveExercise(source, to: group, at: targetRow.orderIndex)
    }
}

private struct RenameGroupSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let group: MuscleGroupEntity
    @Binding var isPresented: Bool

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $name)
            }
            .navigationTitle("Rename Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.renameMuscleGroup(group, to: name)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear { name = group.name }
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
