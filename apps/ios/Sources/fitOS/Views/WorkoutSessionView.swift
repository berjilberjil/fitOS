import SwiftUI

/// Today's training session — seeded from the weekly routine, with weight/sets/reps
/// steppers, done toggles, and progressive-overload starting weights.
struct WorkoutSessionView: View {
    @EnvironmentObject var state: AppState
    @State private var showPicker = false
    @State private var detail: Exercise?

    var body: some View {
        let session = state.todaySession
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Card {
                    Toggle(isOn: Binding(get: { session.rest }, set: { state.setTodayRest($0) })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rest day").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                            Text(WEEKDAYS_LONG[state.todayWeekday]).font(.system(size: 12)).foregroundStyle(Palette.muted)
                        }
                    }
                    .tint(Palette.red)
                }

                if session.rest {
                    Card { Text("Rest day — recover well. 💤").font(.system(size: 14)).foregroundStyle(Palette.muted) }
                } else if session.items.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No exercises today").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                            Text("Add exercises below, or build a weekly routine in the Plan tab so today auto-fills.")
                                .font(.system(size: 13)).foregroundStyle(Palette.muted)
                        }
                    }
                } else {
                    ForEach(Array(session.items.enumerated()), id: \.offset) { idx, item in
                        exerciseCard(idx, item)
                    }
                }

                if !session.rest {
                    Button { showPicker = true } label: {
                        Label("Add exercise", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(Palette.red)
                            .background(Palette.redSoft)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
        }
        .background(Palette.bg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { state.addExerciseToday($0) }
        }
        .sheet(item: $detail) { ExerciseDetailSheet(exercise: $0) }
    }

    private func exerciseCard(_ idx: Int, _ item: LoggedExercise) -> some View {
        let ex = state.exercisesById[item.exerciseId]
        let weighted = ex?.weighted ?? true
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button { if let ex { detail = ex } } label: {
                        HStack(spacing: 10) {
                            Text(ex?.icon ?? "🏋️").font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex?.name ?? item.exerciseId)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Palette.text)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let p = ex?.primary {
                                    Text(p).font(.system(size: 12)).foregroundStyle(Palette.faint).lineLimit(1)
                                }
                            }
                            Image(systemName: "play.circle").font(.system(size: 13)).foregroundStyle(Palette.faint)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button { Haptics.tap(); state.toggleDone(index: idx) } label: {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundStyle(item.done ? Palette.ok : Palette.faint)
                    }
                }

                HStack(spacing: 10) {
                    CompactIntControl(label: "Sets", value: item.sets, range: 1...20, digits: 2) {
                        state.setLogSets(index: idx, $0)
                    }
                    CompactIntControl(label: "Reps", value: item.reps, range: 1...50, digits: 2) {
                        state.setLogReps(index: idx, $0)
                    }
                }

                if weighted {
                    CompactWeightControl(valueKg: item.weightKg) { delta in
                        state.bumpWeight(index: idx, delta: delta)
                    }
                }

                Button(role: .destructive) { state.removeToday(index: idx) } label: {
                    Text("Remove").font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.red)
                }
            }
        }
    }
}
