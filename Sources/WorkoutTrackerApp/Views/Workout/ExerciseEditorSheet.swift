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
    @State private var selectedSecondaryGroups: [String] = []
    @State private var notes: String = ""
    @State private var selectedPrimaryGroupID: UUID?
    @State private var selectedWeekday: Int?
    @State private var selectedCustomSlot: String?
    @State private var selectedCategory: ExerciseCategory = .exercise
    @State private var weeklyTargetValue: Int = 1
    @State private var durationInput: String = ""
    @State private var intensityInput: String = ""
    @State private var inclineInput: String = ""
    @State private var distanceInput: String = ""
    @State private var heartRateInput: String = ""
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

                    Picker("Category", selection: $selectedCategory) {
                        Text("Exercise").tag(ExerciseCategory.exercise)
                        Text("Stretch").tag(ExerciseCategory.stretch)
                        Text("Cardio").tag(ExerciseCategory.cardio)
                    }
                    .pickerStyle(.segmented)

                    Picker("Primary Muscle Group", selection: $selectedPrimaryGroupID) {
                        Text("Select group").tag(Optional<UUID>.none)
                        ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }

                    SecondaryMuscleGroupPicker(
                        selectedGroups: $selectedSecondaryGroups,
                        availableGroups: repository.muscleGroups.filter { !$0.isArchived }.map(\.name),
                        primaryGroupName: repository.muscleGroups.first { $0.id == selectedPrimaryGroupID }?.name ?? ""
                    )
                }

                Section("Targets") {
                    if selectedCategory != .cardio {
                        HStack {
                            Text("Sets")
                            TextField("0", text: $sets)
                                .numberPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if selectedCategory == .exercise {
                        Toggle("Use Seconds Instead Of Reps", isOn: $useSeconds)

                        if useSeconds {
                            HStack {
                                Text("Seconds")
                                TextField("0", text: $seconds)
                                    .numberPadKeyboardIfAvailable()
                                    .multilineTextAlignment(.trailing)
                            }
                        } else {
                            HStack {
                                Text("Reps")
                                TextField("0", text: $reps)
                                    .numberPadKeyboardIfAvailable()
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        HStack {
                            Text("Weight (\(repository.unitSystem.title.uppercased()))")
                            TextField("BW", text: $weightInput)
                                .decimalPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if selectedCategory == .stretch {
                        HStack {
                            Text("Seconds")
                            TextField("0", text: $seconds)
                                .numberPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if selectedCategory == .cardio {
                        HStack {
                            Text("Duration (min)")
                            TextField("0", text: $durationInput)
                                .numberPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Intensity")
                            TextField("e.g. Level 15", text: $intensityInput)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Distance (km)")
                            TextField("Optional", text: $distanceInput)
                                .decimalPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Incline (%)")
                            TextField("Optional", text: $inclineInput)
                                .decimalPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Heart Rate Target")
                            TextField("Optional", text: $heartRateInput)
                                .numberPadKeyboardIfAvailable()
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Stepper("Times per week: \(weeklyTargetValue)", value: $weeklyTargetValue, in: 1...7)
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
        selectedCategory = exercise.category
        weeklyTargetValue = exercise.weeklyTarget

        if let kg = exercise.weightKg {
            switch repository.unitSystem {
            case .kg:
                weightInput = kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
            case .lb:
                let lb = kg * 2.2046226218
                weightInput = lb.rounded() == lb ? String(Int(lb)) : String(format: "%.1f", lb)
            }
        }

        durationInput = exercise.durationMinutes.map(String.init) ?? ""
        intensityInput = exercise.intensityLabel
        inclineInput = exercise.inclinePercent.map { String(format: "%.1f", $0) } ?? ""
        distanceInput = exercise.distanceKm.map { String(format: "%.1f", $0) } ?? ""
        heartRateInput = exercise.heartRateTarget.map(String.init) ?? ""

        selectedSecondaryGroups = exercise.secondaryMuscleGroupsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
        exercise.categoryRaw = selectedCategory.rawValue
        exercise.weeklyTarget = weeklyTargetValue

        switch selectedCategory {
        case .exercise:
            exercise.sets = Int(sets.filter { $0.isNumber })
            if useSeconds {
                exercise.seconds = Int(seconds.filter { $0.isNumber })
                exercise.reps = nil
            } else {
                exercise.reps = Int(reps.filter { $0.isNumber })
                exercise.seconds = nil
            }
            exercise.weightKg = Formatting.parseWeightEntry(weightInput, unit: repository.unitSystem)
            // Clear cardio fields
            exercise.durationMinutes = nil
            exercise.intensityLabel = ""
            exercise.inclinePercent = nil
            exercise.distanceKm = nil
            exercise.heartRateTarget = nil

        case .stretch:
            exercise.sets = Int(sets.filter { $0.isNumber })
            exercise.seconds = Int(seconds.filter { $0.isNumber })
            exercise.reps = nil
            exercise.weightKg = nil
            // Clear cardio fields
            exercise.durationMinutes = nil
            exercise.intensityLabel = ""
            exercise.inclinePercent = nil
            exercise.distanceKm = nil
            exercise.heartRateTarget = nil

        case .cardio:
            exercise.sets = nil
            exercise.reps = nil
            exercise.seconds = nil
            exercise.weightKg = nil
            exercise.durationMinutes = Int(durationInput.filter { $0.isNumber })
            exercise.intensityLabel = intensityInput.trimmingCharacters(in: .whitespacesAndNewlines)
            exercise.distanceKm = Double(distanceInput.replacingOccurrences(of: ",", with: "."))
            exercise.inclinePercent = Double(inclineInput.replacingOccurrences(of: ",", with: "."))
            exercise.heartRateTarget = Int(heartRateInput.filter { $0.isNumber })
        }

        exercise.secondaryMuscleGroupsRaw = selectedSecondaryGroups.joined(separator: ",")
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
