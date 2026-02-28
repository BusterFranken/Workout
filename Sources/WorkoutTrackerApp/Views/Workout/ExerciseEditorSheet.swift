import SwiftUI

struct ExerciseEditorSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Binding var isPresented: Bool

    let exercise: WeeklyExerciseEntity

    @State private var name: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var seconds: String = ""
    @State private var useSeconds: Bool = false
    @State private var weightInput: String = ""
    @FocusState private var focusName: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                        .focused($focusName)
                }

                Section("Targets") {
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)

                    Toggle("Use Seconds Instead Of Reps", isOn: $useSeconds)

                    if useSeconds {
                        TextField("Seconds", text: $seconds)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                    }

                    TextField("Weight (e.g. 16 or 16x2 or BW)", text: $weightInput)
                }

                Section {
                    Text("Empty weight means bodyweight (BW). For dumbbells use format 16x2.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyChanges()
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
            if let count = exercise.weightCount, count > 1 {
                let compact = kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
                weightInput = "\(compact)x\(count)"
            } else {
                weightInput = kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
            }
        } else {
            weightInput = "BW"
        }
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

        let parsed = Formatting.parseWeightEntry(weightInput)
        exercise.weightKg = parsed.weightKg
        exercise.weightCount = parsed.count

        repository.updateExercise(exercise)
    }
}
