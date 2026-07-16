import SwiftUI

/// Weekly workout routine editor. Pick a weekday, mark rest, add exercises with
/// target sets/reps. Today's session auto-seeds from this.
struct WorkoutPlanView: View {
    @EnvironmentObject var state: AppState
    @State private var weekday = AppState.weekday(of: AppState.dateKey(Date()))
    @State private var showPicker = false

    var body: some View {
        let day = state.planDay(weekday)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                WeekdayPicker(selected: $weekday)

                Card {
                    Toggle(isOn: Binding(get: { day.rest }, set: { state.setRestDay(weekday: weekday, $0) })) {
                        Text("Rest day").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                    }
                    .tint(Palette.red)
                }

                if day.rest {
                    Card { Text("\(WEEKDAYS_LONG[weekday]) is a rest day.").font(.system(size: 14)).foregroundStyle(Palette.muted) }
                } else {
                    if day.items.isEmpty {
                        Card { Text("No exercises planned for \(WEEKDAYS_LONG[weekday]).").font(.system(size: 13)).foregroundStyle(Palette.muted) }
                    } else {
                        ForEach(Array(day.items.enumerated()), id: \.offset) { idx, item in
                            planCard(idx, item)
                        }
                    }
                    Button { showPicker = true } label: {
                        Label("Add exercise", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .foregroundStyle(Palette.red).background(Palette.redSoft).clipShape(Capsule())
                    }
                }
            }
            .padding(16)
        }
        .background(Palette.bg)
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { state.addPlanExercise(weekday: weekday, exerciseId: $0) }
        }
    }

    private func planCard(_ idx: Int, _ item: PlanExercise) -> some View {
        let ex = state.exercisesById[item.exerciseId]
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(ex?.icon ?? "🏋️").font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex?.name ?? item.exerciseId).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                        if let p = ex?.primary { Text(p).font(.system(size: 12)).foregroundStyle(Palette.faint) }
                    }
                    Spacer()
                    Button(role: .destructive) { state.removePlanExercise(weekday: weekday, index: idx) } label: {
                        Image(systemName: "trash").font(.system(size: 15)).foregroundStyle(Palette.faint)
                    }
                }
                HStack(spacing: 10) {
                    labeledStepper("Sets", value: item.sets, range: 1...20) { state.setPlanSets(weekday: weekday, index: idx, $0) }
                    labeledStepper("Reps", value: item.reps, range: 1...50) { state.setPlanReps(weekday: weekday, index: idx, $0) }
                }
            }
        }
    }

    private func labeledStepper(_ label: String, value: Int, range: ClosedRange<Int>, set: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.muted)
            Spacer()
            Text("\(value)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Palette.text)
            Stepper("", value: Binding(get: { value }, set: { set($0) }), in: range).labelsHidden()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Palette.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }
}
