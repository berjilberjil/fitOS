import SwiftUI

/// Exercise demo popup — animated gif demonstration + facts, optional "add to today".
struct ExerciseDetailSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    var onAdd: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ExerciseDemoView(media: state.mediaFor(exercise.id), emoji: exercise.icon)

                    HStack(spacing: 10) {
                        Text(exercise.icon).font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
                            Text(exercise.primary).font(.system(size: 13)).foregroundStyle(Palette.muted)
                        }
                    }

                    Card {
                        VStack(spacing: 0) {
                            factRow("Category", exercise.category.capitalized)
                            Divider().overlay(Palette.border)
                            factRow("Equipment", exercise.equipment)
                            Divider().overlay(Palette.border)
                            factRow("Targets", exercise.primary)
                            Divider().overlay(Palette.border)
                            factRow("Load", exercise.weighted ? "Weighted" : "Bodyweight")
                        }
                    }

                    if let onAdd {
                        PrimaryButton(title: "＋ Add to today") { onAdd(); dismiss() }
                    }
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.faint)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.text)
        }
        .padding(.vertical, 10)
    }
}
