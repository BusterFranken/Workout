import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

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
                            templateCard(for: template)
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
            .libraryGroupedListStyle()
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

    // MARK: - Template Card

    @ViewBuilder
    private func templateCard(for template: WorkoutTemplateEntity) -> some View {
        let exercises = repository.templateExercises.filter { $0.templateID == template.id }
        let muscleGroups = Array(Set(exercises.map(\.muscleGroupName)).sorted())
        let exerciseCount = exercises.count
        let estimatedMinutes = exerciseCount * 4

        VStack(alignment: .leading, spacing: 8) {
            // Banner image
            if let imageData = template.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Button {
                    selectedTemplate = template
                    Haptics.selection()
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            // Emoji + title row
            HStack(spacing: 10) {
                Button {
                    selectedTemplate = template
                    Haptics.selection()
                } label: {
                    if let emoji = template.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 28))
                    } else {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    selectedTemplate = template
                    Haptics.selection()
                } label: {
                    Text(template.name)
                        .font(.rowTitle)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                }
                .buttonStyle(.plain)
            }

            // Muscle group chips + stats
            if !muscleGroups.isEmpty || exerciseCount > 0 {
                HStack(alignment: .top) {
                    if !muscleGroups.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Text(group)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Theme.mutedSurface)
                                    )
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }

                    Spacer()

                    if exerciseCount > 0 {
                        Text("\(exerciseCount) ex · ~\(estimatedMinutes)m")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            // Add button
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryText)
            TextField("Search by name, muscle group, or synonym", text: $searchText)
                .neverAutocapitalizeIfAvailable()
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

// MARK: - Workout Template Detail Sheet

private struct WorkoutTemplateDetailSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Environment(\.dismiss) private var dismiss
    let template: WorkoutTemplateEntity

    @State private var editedName: String = ""
    @State private var editedNotes: String = ""
    @State private var showingEmojiPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var exercises: [WorkoutTemplateExerciseEntity] {
        repository.templateExercises
            .filter { $0.templateID == template.id }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var groupedRows: [(String, [WorkoutTemplateExerciseEntity])] {
        let grouped = Dictionary(grouping: exercises, by: { $0.muscleGroupName })
        return grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
    }

    private var exerciseCount: Int { exercises.count }
    private var muscleGroupCount: Int { Set(exercises.map(\.muscleGroupName)).count }
    private var estimatedMinutes: Int { exerciseCount * 4 }

    var body: some View {
        NavigationStack {
            List {
                // Hero section
                Section {
                    heroSection
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                // Quick stats
                if exerciseCount > 0 {
                    Section {
                        HStack(spacing: 8) {
                            statPill("\(exerciseCount) exercises")
                            statPill("\(muscleGroupCount) muscle groups")
                            statPill("~\(estimatedMinutes) min")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Exercise list grouped by muscle group
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
            .navigationTitle("Workout Details")
            .inlineNavigationTitleDisplayModeIfAvailable()
            .libraryGroupedListStyle()
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerSheet(
                    currentEmoji: template.emoji,
                    onSelect: { emoji in
                        template.emoji = emoji
                        repository.updateTemplate(template)
                    },
                    onRemove: {
                        template.emoji = nil
                        repository.updateTemplate(template)
                    }
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
            .onAppear {
                editedName = template.name
                editedNotes = template.notes ?? ""
            }
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover image
            coverImageView

            // Emoji + Name row
            HStack(spacing: 10) {
                Button {
                    showingEmojiPicker = true
                    Haptics.selection()
                } label: {
                    if let emoji = template.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 44))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Theme.mutedSurface)
                                .frame(width: 48, height: 48)
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)

                TextField("Workout Name", text: $editedName)
                    .font(.sectionTitle)
                    .foregroundStyle(Theme.primaryText)
                    .onSubmit {
                        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            template.name = trimmed
                            repository.updateTemplate(template)
                        }
                    }
            }

            // Notes
            TextField("Add a description...", text: $editedNotes, axis: .vertical)
                .font(.rowBody)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1...5)
                .onSubmit {
                    template.notes = editedNotes.isEmpty ? nil : editedNotes
                    repository.updateTemplate(template)
                }
                .onChange(of: editedNotes) { _, newValue in
                    template.notes = newValue.isEmpty ? nil : newValue
                    repository.updateTemplate(template)
                }
        }
    }

    // MARK: - Cover Image

    @ViewBuilder
    private var coverImageView: some View {
        if let imageData = template.coverImageData,
           let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 8) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text("Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Button {
                        template.coverImageData = nil
                        repository.updateTemplate(template)
                        Haptics.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                }
                .padding(8)
            }
        } else {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack {
                    Image(systemName: "camera")
                    Text("Add Cover Photo")
                }
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(Theme.border)
                )
            }
        }
    }

    // MARK: - Helpers

    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.mutedSurface)
            )
            .foregroundStyle(Theme.secondaryText)
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

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data,
                          let uiImage = UIImage(data: data),
                          let thumbnail = uiImage.preparingThumbnail(of: CGSize(width: 800, height: 800)),
                          let jpeg = thumbnail.jpegData(compressionQuality: 0.7) else { return }
                    template.coverImageData = jpeg
                    repository.updateTemplate(template)
                    Haptics.success()
                case .failure:
                    break
                }
                selectedPhotoItem = nil
            }
        }
    }
}

// MARK: - Emoji Keyboard UIViewRepresentable

#if canImport(UIKit)
private class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
    }
}

private struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 40)
        field.tintColor = .clear
        field.becomeFirstResponder()
        return field
    }

    func updateUIView(_ uiView: EmojiUITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let filtered = string.filter { $0.unicodeScalars.first?.properties.isEmojiPresentation == true }
            if let last = filtered.last {
                text.wrappedValue = String(last)
            }
            return false
        }
    }
}
#endif

// MARK: - Emoji Picker Sheet

private struct EmojiPickerSheet: View {
    let currentEmoji: String?
    let onSelect: (String) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(inputText.isEmpty ? "🏋️" : inputText)
                    .font(.system(size: 72))
                    .padding(.top, 24)

                EmojiTextField(text: $inputText)
                    .frame(height: 60)

                if currentEmoji != nil {
                    Button("Remove Emoji", role: .destructive) {
                        onRemove()
                        Haptics.selection()
                        dismiss()
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Choose Emoji")
            .inlineNavigationTitleDisplayModeIfAvailable()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if !inputText.isEmpty {
                            onSelect(inputText)
                            Haptics.success()
                        }
                        dismiss()
                    }
                    .disabled(inputText.isEmpty)
                }
            }
            .onAppear {
                inputText = currentEmoji ?? ""
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Exercise Library Detail Sheet

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
            .inlineNavigationTitleDisplayModeIfAvailable()
            .libraryGroupedListStyle()
        }
    }
}

// MARK: - View Extensions

private extension View {
    @ViewBuilder
    func inlineNavigationTitleDisplayModeIfAvailable() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func libraryGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }

    @ViewBuilder
    func neverAutocapitalizeIfAvailable() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}
