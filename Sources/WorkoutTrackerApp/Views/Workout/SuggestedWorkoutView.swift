import SwiftUI

struct SuggestedWorkoutView: View {
    @EnvironmentObject private var repository: WorkoutRepository

    let onRowEdit: (WeeklyExerciseEntity) -> Void
    let onRowDetail: (WeeklyExerciseEntity) -> Void
    let onRowDelete: (WeeklyExerciseEntity) -> Void
    let onMarkDone: (WeeklyExerciseEntity) -> Void

    @State private var showingSettingsSheet = false
    @State private var showAllDoneCheckmark = false
    @State private var isCollapsed = false

    var body: some View {
        let exercises = repository.cachedSuggestedExercises.filter {
            $0.completedAt == nil && !repository.hasCompletionToday(for: $0)
        }

        if !exercises.isEmpty || repository.allSuggestedExercisesDone {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                    Text("Today's Suggestion")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Button {
                        showingSettingsSheet = true
                        Haptics.selection()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isCollapsed.toggle()
                    }
                }

                if !isCollapsed {
                    if repository.allSuggestedExercisesDone {
                        allDoneView
                    } else {
                        exerciseList(exercises)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(cornerRadius: 18)
            .sheet(isPresented: $showingSettingsSheet) {
                SuggestionSettingsSheet(isPresented: $showingSettingsSheet)
            }
        }
    }

    private func exerciseList(_ exercises: [WeeklyExerciseEntity]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRowView(
                    exercise: exercise,
                    isReordering: false,
                    isActiveDragItem: false,
                    activeDragExerciseID: nil,
                    rowIndex: index,
                    onOpenEditor: { onRowEdit(exercise) },
                    onOpenDetail: { onRowDetail(exercise) },
                    onDelete: { onRowDelete(exercise) },
                    onMarkDone: { onMarkDone(exercise) },
                    onStartDrag: { _ in },
                    onDropAtIndex: { _, _ in },
                    hoveredInsertionIndex: .constant(nil)
                )
            }
        }
    }

    private var allDoneView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
                .scaleEffect(showAllDoneCheckmark ? 1.0 : 0.3)
                .opacity(showAllDoneCheckmark ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.55), value: showAllDoneCheckmark)

            Text("You crushed it!")
                .font(.headline)

            Text("Every rep counts. Rest up and come back stronger.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .onAppear {
            showAllDoneCheckmark = true
            Haptics.success()
        }
    }
}

private struct SuggestionSettingsSheet: View {
    @EnvironmentObject private var repository: WorkoutRepository
    @Binding var isPresented: Bool

    @State private var strengthCount: Int = 3
    @State private var stretchCount: Int = 1
    @State private var cardioCount: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Strength exercises: \(strengthCount)", value: $strengthCount, in: 0...10)
                    Stepper("Stretch exercises: \(stretchCount)", value: $stretchCount, in: 0...10)
                    Stepper("Cardio exercises: \(cardioCount)", value: $cardioCount, in: 0...10)
                }

                Section {
                    Text("Exercises are prioritised based on the goals you set on your headers.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Suggestion Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.updateSuggestedStrengthCount(strengthCount)
                        repository.updateSuggestedStretchCount(stretchCount)
                        repository.updateSuggestedCardioCount(cardioCount)
                        isPresented = false
                        Haptics.success()
                    }
                }
            }
        }
        .onAppear {
            strengthCount = repository.suggestedStrengthCount
            stretchCount = repository.suggestedStretchCount
            cardioCount = repository.suggestedCardioCount
        }
    }
}
