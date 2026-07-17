import SwiftUI

/// Exercise demo popup — animated gif demonstration + facts, optional "add to today".
struct ExerciseDetailSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    var onAdd: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ExerciseDemoView(
                            media: state.mediaFor(exercise.id),
                            emoji: exercise.icon,
                            height: 240
                        )

                        HStack(alignment: .top, spacing: 10) {
                            Text(exercise.icon).font(.system(size: 30))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Palette.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(exercise.primary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
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
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let onAdd {
                    PrimaryButton(title: "＋ Add to today") { onAdd(); dismiss() }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Palette.bg)
                }
            }
            .background(Palette.bg)
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }

        }
        // Keep the sheet from stretching with oversized media.
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.faint)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
    }
}
