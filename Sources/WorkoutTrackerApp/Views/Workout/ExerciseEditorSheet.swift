import SwiftUI

struct ExerciseEditorSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Binding var isPresented: Bool

    let exercise: WeeklyExerciseEntity
    let isNewExercise: Bool
    let onCancelNew: (() -> Void)?
    let onSave: (() -> Void)?

    @State private var name: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var seconds: String = ""
    @State private var useSeconds: Bool = false
    @State private var weightInput: String = ""
    @State private var secondaryGroupsInput: String = ""
    @State private var notes: String = ""
    @State private var selectedPrimaryGroupID: UUID?
    @State private var selectedWeekday: Int?
    @State private var selectedCustomSlot: String?
    @FocusState private var focusName: Bool

    init(
        isPresented: Binding<Bool>,
        exercise: WeeklyExerciseEntity,
        isNewExercise: Bool = false,
        onCancelNew: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil
    ) {
        _isPresented = isPresented
        self.exercise = exercise
        self.isNewExercise = isNewExercise
        self.onCancelNew = onCancelNew
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                        .focused($focusName)

                    Picker("Primary Muscle Group", selection: $selectedPrimaryGroupID) {
                        Text("Select group").tag(Optional<UUID>.none)
                        ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }

                    TextField("Secondary muscle groups (comma-separated)", text: $secondaryGroupsInput)
                }

                Section("Targets") {
                    TextField("Sets", text: $sets)
                        .numberPadKeyboardIfAvailable()

                    Toggle("Use Seconds Instead Of Reps", isOn: $useSeconds)

                    if useSeconds {
                        TextField("Seconds", text: $seconds)
                            .numberPadKeyboardIfAvailable()
                    } else {
                        TextField("Reps", text: $reps)
                            .numberPadKeyboardIfAvailable()
                    }

                    TextField("Weight (\(repository.unitSystem.title.uppercased()) or BW)", text: $weightInput)
                        .decimalPadKeyboardIfAvailable()
                }

                Section("Scheduling") {
                    Picker("Weekday", selection: $selectedWeekday) {
                        Text("No day").tag(Optional<Int>.none)
                        Text("Monday").tag(Optional(1))
                        Text("Tuesday").tag(Optional(2))
                        Text("Wednesday").tag(Optional(3))
                        Text("Thursday").tag(Optional(4))
                        Text("Friday").tag(Optional(5))
                        Text("Saturday").tag(Optional(6))
                        Text("Sunday").tag(Optional(7))
                    }

                    Picker("Custom Workout", selection: $selectedCustomSlot) {
                        Text("No custom slot").tag(Optional<String>.none)
                        Text("Workout A").tag(Optional("A"))
                        Text("Workout B").tag(Optional("B"))
                        Text("Workout C").tag(Optional("C"))
                        Text("Workout D").tag(Optional("D"))
                        Text("Workout E").tag(Optional("E"))
                    }
                }

                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isNewExercise {
                            onCancelNew?()
                        }
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyChanges()
                        onSave?()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        name = exercise.name
        sets = exercise.sets.map(String.init) ?? ""
        reps = exercise.reps.map(String.init) ?? ""
        seconds = exercise.seconds.map(String.init) ?? ""
        useSeconds = exercise.seconds != nil && exercise.reps == nil

        if let kg = exercise.weightKg {
            switch repository.unitSystem {
            case .kg:
                weightInput = kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
            case .lb:
                let lb = kg * 2.2046226218
                weightInput = lb.rounded() == lb ? String(Int(lb)) : String(format: "%.1f", lb)
            }
        } else {
            weightInput = "BW"
        }

        secondaryGroupsInput = exercise.secondaryMuscleGroupsRaw
        notes = exercise.notes
        selectedPrimaryGroupID = exercise.muscleGroupID
        selectedWeekday = exercise.weekdayIndex
        selectedCustomSlot = exercise.customSlot

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusName = true
        }
    }

    private func applyChanges() {
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.sets = Int(sets.filter { $0.isNumber })

        if useSeconds {
            exercise.seconds = Int(seconds.filter { $0.isNumber })
            exercise.reps = nil
        } else {
            exercise.reps = Int(reps.filter { $0.isNumber })
            exercise.seconds = nil
        }

        exercise.weightKg = Formatting.parseWeightEntry(weightInput, unit: repository.unitSystem)
        exercise.secondaryMuscleGroupsRaw = secondaryGroupsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")

        exercise.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.weekdayIndex = selectedWeekday
        exercise.customSlot = selectedCustomSlot

        if let selectedPrimaryGroupID,
           let group = repository.muscleGroups.first(where: { $0.id == selectedPrimaryGroupID }) {
            exercise.muscleGroupID = group.id
            exercise.muscleGroupName = group.name
        }

        repository.updateExercise(exercise, refresh: true)
    }
}

private extension View {
    @ViewBuilder
    func numberPadKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func decimalPadKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
