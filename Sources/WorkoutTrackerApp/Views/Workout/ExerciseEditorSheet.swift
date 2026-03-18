import PhotosUI
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
    @State private var rpmInput: String = ""
    @State private var selectedSubMuscle: String?
    @State private var instructionSteps: [String] = []
    @State private var instructionImageItems: [PhotosPickerItem] = []
    @State private var instructionImageDatas: [Data] = []
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

                    Picker("Muscle Group", selection: $selectedPrimaryGroupID) {
                        Text("Select group").tag(Optional<UUID>.none)
                        ForEach(repository.muscleGroups.filter { !$0.isArchived }, id: \.id) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }
                    .onChange(of: selectedPrimaryGroupID) { _, _ in
                        selectedSubMuscle = nil
                    }

                    if let groupName = repository.muscleGroups.first(where: { $0.id == selectedPrimaryGroupID })?.name,
                       let subMuscles = SeedCatalog.subMuscles[groupName], !subMuscles.isEmpty {
                        Picker("Muscle", selection: $selectedSubMuscle) {
                            Text("Any / All").tag(Optional<String>.none)
                            ForEach(subMuscles, id: \.self) { sub in
                                Text(sub).tag(Optional(sub))
                            }
                        }
                    }

                    SecondaryMuscleGroupPicker(
                        selectedGroups: $selectedSecondaryGroups,
                        availableGroups: repository.muscleGroups
                            .filter { !$0.isArchived }
                            .flatMap { group in
                                var items = [group.name]
                                if let subs = SeedCatalog.subMuscles[group.name] {
                                    items += subs.map { "\(group.name) (\($0))" }
                                }
                                return items
                            },
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
                        HStack {
                            Text("RPM")
                            TextField("Optional", text: $rpmInput)
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

                Section("Instructions") {
                    ForEach(Array(instructionSteps.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            TextField("Step \(index + 1)", text: $instructionSteps[index])
                            Button {
                                instructionSteps.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        instructionSteps.append("")
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }

                    #if canImport(UIKit)
                    if !instructionImageDatas.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(instructionImageDatas.enumerated()), id: \.offset) { index, data in
                                    ZStack(alignment: .topTrailing) {
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        Button {
                                            instructionImageDatas.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .red)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    #endif

                    if instructionImageDatas.count < 5 {
                        PhotosPicker(
                            selection: $instructionImageItems,
                            maxSelectionCount: 5 - instructionImageDatas.count,
                            matching: .images
                        ) {
                            Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                        }
                        .onChange(of: instructionImageItems) { _, newItems in
                            Task {
                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self) {
                                        if let compressed = compressImage(data) {
                                            instructionImageDatas.append(compressed)
                                        }
                                    }
                                }
                                instructionImageItems.removeAll()
                            }
                        }
                    }
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
        rpmInput = exercise.rpm.map(String.init) ?? ""

        selectedSecondaryGroups = exercise.secondaryMuscleGroupsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        notes = exercise.notes
        selectedPrimaryGroupID = exercise.muscleGroupID
        selectedSubMuscle = exercise.subMuscleName
        selectedWeekday = exercise.weekdayIndex
        selectedCustomSlot = exercise.customSlot
        instructionSteps = exercise.instructionSteps
        instructionImageDatas = exercise.instructionImages

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
            exercise.rpm = nil

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
            exercise.rpm = nil

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
            exercise.rpm = Int(rpmInput.filter { $0.isNumber })
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

        exercise.subMuscleName = selectedSubMuscle

        let filteredSteps = instructionSteps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        exercise.instructionSteps = filteredSteps
        exercise.instructionImages = instructionImageDatas

        repository.updateExercise(exercise, refresh: true)
    }

    private func compressImage(_ data: Data, maxDimension: CGFloat = 800, quality: CGFloat = 0.6) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        if scale >= 1.0 {
            return image.jpegData(compressionQuality: quality)
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
        #else
        return nil
        #endif
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
