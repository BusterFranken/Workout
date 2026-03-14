import SwiftUI

struct SecondaryMuscleGroupPicker: View {
    @Binding var selectedGroups: [String]
    let availableGroups: [String]
    let primaryGroupName: String

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    private var suggestions: [String] {
        let excluded = Set(selectedGroups + [primaryGroupName])
        let candidates = availableGroups.filter { !excluded.contains($0) }
        if searchText.isEmpty {
            return candidates
        }
        return candidates.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !selectedGroups.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(selectedGroups, id: \.self) { group in
                        chip(for: group)
                    }
                }
            }

            TextField("Add secondary group...", text: $searchText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

            if isSearchFocused, !suggestions.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(suggestions, id: \.self) { group in
                        suggestionChip(for: group)
                    }
                }
            }
        }
    }

    private func chip(for group: String) -> some View {
        HStack(spacing: 4) {
            Text(group)
                .font(.subheadline)
            Button {
                selectedGroups.removeAll { $0 == group }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.mutedSurface, in: Capsule())
    }

    private func suggestionChip(for group: String) -> some View {
        Button {
            selectedGroups.append(group)
            searchText = ""
        } label: {
            Text(group)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.15), in: Capsule())
                .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }
}
