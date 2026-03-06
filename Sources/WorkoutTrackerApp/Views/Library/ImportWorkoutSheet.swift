import SwiftUI
import UniformTypeIdentifiers

struct ImportWorkoutSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository

    @Binding var isPresented: Bool

    @State private var rawText = ""
    @State private var selectedURL: URL?
    @State private var targetGroup = "Imported"
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Import Source") {
                    Button("Choose CSV/TXT File") {
                        showingPicker = true
                    }

                    if let selectedURL {
                        Text(selectedURL.lastPathComponent)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }

                    TextEditor(text: $rawText)
                        .frame(minHeight: 180)
                }

                Section("Target Muscle Group") {
                    TextField("Imported", text: $targetGroup)
                }

                Section {
                    Text("Each line becomes one exercise. Basic patterns like 5x8 and 16kg are parsed.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Upload Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importNow()
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showingPicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                guard case let .success(urls) = result,
                      let url = urls.first else {
                    return
                }
                selectedURL = url
                if let data = try? Data(contentsOf: url),
                   let text = String(data: data, encoding: .utf8) {
                    rawText = text
                }
            }
        }
    }

    private func importNow() {
        let parsed = WorkoutImportParser.parse(raw: rawText)
        guard !parsed.isEmpty else { return }
        repository.addImportedLines(parsed, to: targetGroup)
        isPresented = false
    }
}
