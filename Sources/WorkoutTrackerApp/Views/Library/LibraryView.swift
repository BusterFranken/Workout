import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @State private var searchText = ""
    @State private var mode = 0
    @State private var showingImportSheet = false

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
                    } label: {
                        Label("Upload Workout", systemImage: "square.and.arrow.up")
                    }
                }

                if mode == 0 {
                    Section("Saved Workouts") {
                        ForEach(filteredTemplates) { template in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(template.name)
                                    .font(.headline)
                                Button("Add To This Week") {
                                    repository.addTemplateToWeek(template)
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                    Text(exercise.primaryMuscleGroupName)
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                Spacer()
                                Button("Add") {
                                    repository.addCatalogExerciseToWeek(exercise)
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
            .searchable(text: $searchText, prompt: "Search by exercise or muscle group")
            .navigationTitle("Library")
            .sheet(isPresented: $showingImportSheet) {
                ImportWorkoutSheet(isPresented: $showingImportSheet)
            }
        }
    }

    private var filteredTemplates: [WorkoutTemplateEntity] {
        guard !searchText.isEmpty else { return repository.workoutTemplates }

        return repository.workoutTemplates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText)
                || repository.templateExercises
                .filter { $0.templateID == template.id }
                .contains {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                        || $0.muscleGroupName.localizedCaseInsensitiveContains(searchText)
                }
        }
    }

    private var filteredExercises: [ExerciseEntity] {
        guard !searchText.isEmpty else { return repository.exerciseCatalog.filter { !$0.isArchived } }

        return repository.exerciseCatalog.filter {
            !$0.isArchived
                && (
                    $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.primaryMuscleGroupName.localizedCaseInsensitiveContains(searchText)
                )
        }
    }
}
