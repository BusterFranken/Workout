import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @State private var searchText = ""
    @State private var mode = 0
    @State private var showingImportSheet = false

    @State private var pendingTemplate: WorkoutTemplateEntity?
    @State private var replaceTemplate: WorkoutTemplateEntity?
    @State private var showingAddOptions = false
    @State private var showingReplaceWarning = false
    @State private var recentlyAddedTemplateIDs: Set<UUID> = []

    @State private var selectedTemplate: WorkoutTemplateEntity?
    @State private var selectedExercise: ExerciseEntity?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Mode", selection: $mode) {
                        Text("Workouts").tag(0)
                        Text("Exercises").tag(1)
                    }
                    .pickerStyle(.segmented)

                    Button {
                        showingImportSheet = true
                        Haptics.selection()
                    } label: {
                        Label("Upload Workout", systemImage: "square.and.arrow.up")
                    }
                }

                if mode == 0 {
                    Section("Saved Workouts") {
                        ForEach(filteredTemplates) { template in
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    selectedTemplate = template
                                    Haptics.selection()
                                } label: {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundStyle(Theme.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    handleAddTemplate(template)
                                } label: {
                                    HStack {
                                        if recentlyAddedTemplateIDs.contains(template.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                        Text(recentlyAddedTemplateIDs.contains(template.id) ? "Added" : "Add to Weekly Workout")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Section("Exercise Catalogue") {
                        ForEach(filteredExercises) { exercise in
                            HStack {
                                Button {
                                    selectedExercise = exercise
                                    Haptics.selection()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .foregroundStyle(Theme.primaryText)
                                        Text(exercise.primaryMuscleGroupName)
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button("Add") {
                                    repository.addCatalogExerciseToWeek(exercise)
                                    Haptics.success()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Library")
            .sheet(isPresented: $showingImportSheet) {
                ImportWorkoutSheet(isPresented: $showingImportSheet)
            }
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateDetailSheet(template: template)
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseLibraryDetailSheet(exercise: exercise)
            }
            .confirmationDialog(
                "Add workout to weekly plan",
                isPresented: $showingAddOptions,
                titleVisibility: .visible
            ) {
                Button("Add all exercises") {
                    if let pendingTemplate {
                        repository.addTemplateToWeek(pendingTemplate, behavior: .addAllUnique)
                        markTemplateAdded(pendingTemplate)
                    }
                }
                Button("Replace current workout", role: .destructive) {
                    replaceTemplate = pendingTemplate
                    showingReplaceWarning = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You already have exercises in your weekly workout.")
            }
            .alert("Replace current workout?", isPresented: $showingReplaceWarning) {
                Button("Replace", role: .destructive) {
                    if let replaceTemplate {
                        repository.addTemplateToWeek(replaceTemplate, behavior: .replaceCurrent)
                        markTemplateAdded(replaceTemplate)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete your current weekly workout exercises before adding the selected workout.")
            }
            .safeAreaInset(edge: .bottom) {
                searchBar
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryText)
            TextField("Search by name, muscle group, or synonym", text: $searchText)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.shadow, radius: 7, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Theme.background)
    }

    private func handleAddTemplate(_ template: WorkoutTemplateEntity) {
        pendingTemplate = template

        if repository.hasAnyActiveExercise {
            showingAddOptions = true
        } else {
            repository.addTemplateToWeek(template, behavior: .addAllUnique)
            markTemplateAdded(template)
        }
    }

    private func markTemplateAdded(_ template: WorkoutTemplateEntity) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = recentlyAddedTemplateIDs.insert(template.id)
        }
        Haptics.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = recentlyAddedTemplateIDs.remove(template.id)
            }
        }
    }

    private var filteredTemplates: [WorkoutTemplateEntity] {
        guard !searchText.isEmpty else { return repository.workoutTemplates }
        let needle = searchText.lowercased()

        return repository.workoutTemplates.filter { template in
            if template.name.lowercased().contains(needle) {
                return true
            }

            return repository.templateExercises
                .filter { $0.templateID == template.id }
                .contains {
                    $0.name.lowercased().contains(needle)
                        || $0.muscleGroupName.lowercased().contains(needle)
                        || $0.secondaryMuscleGroupsRaw.lowercased().contains(needle)
                }
        }
    }

    private var filteredExercises: [ExerciseEntity] {
        guard !searchText.isEmpty else { return repository.exerciseCatalog.filter { !$0.isArchived } }
        let needle = searchText.lowercased()

        return repository.exerciseCatalog.filter {
            !$0.isArchived
                && (
                    $0.name.lowercased().contains(needle)
                    || $0.primaryMuscleGroupName.lowercased().contains(needle)
                    || $0.secondaryMuscleGroupsRaw.lowercased().contains(needle)
                    || $0.synonymsRaw.lowercased().contains(needle)
                )
        }
    }
}

private struct WorkoutTemplateDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    let template: WorkoutTemplateEntity

    private var groupedRows: [(String, [WorkoutTemplateExerciseEntity])] {
        let rows = repository.templateExercises
            .filter { $0.templateID == template.id }
            .sorted { $0.orderIndex < $1.orderIndex }

        let grouped = Dictionary(grouping: rows, by: { $0.muscleGroupName })

        return grouped
            .keys
            .sorted()
            .map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedRows, id: \.0) { group, rows in
                    Section(group) {
                        ForEach(rows, id: \.id) { row in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name)
                                Text(detailLine(for: row))
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }

    private func detailLine(for row: WorkoutTemplateExerciseEntity) -> String {
        let repLabel: String
        if let reps = row.reps {
            repLabel = "\(reps)rp"
        } else if let seconds = row.seconds {
            repLabel = "\(seconds)s"
        } else {
            repLabel = "--"
        }

        let setLabel = row.sets.map { "\($0)st" } ?? "--"
        let weight = Formatting.compactWeight(row.weightKg, unit: .kg)
        return "\(setLabel) \(repLabel) \(weight)"
    }
}

private struct ExerciseLibraryDetailSheet: View {
    let exercise: ExerciseEntity

    var body: some View {
        NavigationStack {
            List {
                Section("Primary") {
                    Text(exercise.primaryMuscleGroupName)
                }

                if !exercise.secondaryMuscleGroupsRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Secondary Muscle Groups") {
                        Text(exercise.secondaryMuscleGroupsRaw)
                    }
                }

                if !exercise.synonymsRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Synonyms") {
                        Text(exercise.synonymsRaw)
                    }
                }

                if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Notes") {
                        Text(exercise.notes)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }
}
