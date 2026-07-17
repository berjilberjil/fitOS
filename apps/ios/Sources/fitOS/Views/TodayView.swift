import SwiftUI

/// Unified daily hub — food + workout logging in one place, one shared mic.
struct TodayView: View {
    @EnvironmentObject var state: AppState
    @State private var showVoice = false
    @State private var showFoodPicker = false
    @State private var showExercisePicker = false
    @State private var detail: Exercise?
    @State private var segment = 0 // 0 food, 1 workout

    private var targets: Macros { Nutrition.macroTargets(state.profile) }
    private var eaten: Macros { Nutrition.consumed(day: state.todayLog, foodsById: state.foodsById) }
    private var session: WorkoutDayLog { state.todaySession }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let err = state.lastHydrateError { banner(err) }
                    if let sync = state.lastSyncError { banner(sync) }

                    calorieCard
                    macrosCard

                    // Shared mic — food + workout
                    voiceBar

                    Picker("", selection: $segment) {
                        Text("Food").tag(0)
                        Text("Workout").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if segment == 0 {
                        mealsCard
                        Button { showFoodPicker = true } label: {
                            Label("Log food", systemImage: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .foregroundStyle(Palette.red).background(Palette.redSoft)
                                .clipShape(Capsule())
                        }
                    } else {
                        workoutCard
                        if !session.rest {
                            Button { showExercisePicker = true } label: {
                                Label("Add exercise", systemImage: "plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .foregroundStyle(Palette.red).background(Palette.redSoft)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle("Today")

            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { Haptics.tap(); showVoice = true } label: {
                        Image(systemName: "mic.fill")
                    }.tint(Palette.red)
                }
            }
            .refreshable { await state.refresh() }
            .sheet(isPresented: $showVoice) { UnifiedVoiceLogSheet() }
            .sheet(isPresented: $showFoodPicker) {
                FoodPickerSheet { foodId in
                    state.logFood(meal: LogFoodSheet.guessMeal(), foodId: foodId, quantity: 1)
                    Haptics.success()
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { state.addExerciseToday($0) }
            }
            .sheet(item: $detail) { ExerciseDetailSheet(exercise: $0) }
        }
        .accessibilityIdentifier("screen.today")
    }

    private func banner(_ msg: String) -> some View {
        Text(msg)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Palette.warn)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }

    // MARK: - Mic strip

    private var voiceBar: some View {
        Button { Haptics.tap(); showVoice = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Palette.redSoft).frame(width: 44, height: 44)
                    Image(systemName: "mic.fill").foregroundStyle(Palette.red)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice log").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                    Text("Food, workout, or both — one mic.")
                        .font(.system(size: 12)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.faint)
            }
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrition

    private var calorieCard: some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calories").eyebrow()
                    Text("\(Int(eaten.calories.rounded()))")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.text)
                        .accessibilityIdentifier("today.calories")
                    Text("of \(Int(targets.calories.rounded())) kcal · \(Int(max(0, targets.calories - eaten.calories).rounded())) left")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                }
                Spacer()
                MacroRing(value: eaten.calories, target: targets.calories,
                          label: "Intake", unit: "kcal", size: 96)
            }
        }
    }

    private var macrosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Macros").eyebrow()
                MacroBar(label: "Protein", value: eaten.protein, target: targets.protein, tint: Palette.red)
                MacroBar(label: "Carbs", value: eaten.carbs, target: targets.carbs, tint: Palette.info)
                MacroBar(label: "Fiber", value: eaten.fiber, target: targets.fiber, tint: Palette.ok)
                MacroBar(label: "Fats", value: eaten.fats, target: targets.fats, tint: Palette.warn)
            }
        }
    }

    // MARK: - Food log

    private var mealsCard: some View {
        let day = state.todayLog
        let hasAny = MealKey.allCases.contains { !(day.meals[$0.rawValue] ?? []).isEmpty }
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today's meals").eyebrow()
                if !hasAny {
                    Text("Nothing logged yet. Use the mic, Log food, or set a weekly Food Plan.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                } else {
                    ForEach(MealKey.allCases) { meal in
                        let items = day.meals[meal.rawValue] ?? []
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(meal.icon)  \(meal.label)")
                                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
                                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                                    mealRow(meal: meal, index: idx, item: item)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func mealRow(meal: MealKey, index: Int, item: PlanItem) -> some View {
        let food = state.foodsById[item.foodId]
        let q = item.quantity
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("\(food?.icon ?? "❓")  \(food?.name ?? item.foodId)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(food == nil ? Palette.warn : Palette.text)
                    .lineLimit(2)
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    Button {
                        Haptics.tap()
                        state.setFoodQty(meal: meal, index: index, quantity: max(item.quantity - 0.5, 0))
                    } label: { Image(systemName: "minus.circle.fill").foregroundStyle(Palette.faint) }
                    .buttonStyle(.plain)
                    Text(qty(item.quantity))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.faint).monospacedDigit().frame(minWidth: 28)
                    Button {
                        Haptics.tap()
                        state.setFoodQty(meal: meal, index: index, quantity: item.quantity + 0.5)
                    } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Palette.faint) }
                    .buttonStyle(.plain)
                }
                Button {
                    Haptics.warning()
                    state.removeFood(meal: meal, index: index)
                } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundStyle(Palette.faint)
                }
                .buttonStyle(.plain)
            }
            if let m = food?.perServing {
                Text("\(Int((m.calories * q).rounded())) kcal · P\(Int((m.protein * q).rounded())) · C\(Int((m.carbs * q).rounded())) · Fi\(Int((m.fiber * q).rounded())) · F\(Int((m.fats * q).rounded()))")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Palette.faint)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Workout log (same AppState logic as Workout → Today)

    private var workoutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's workout").eyebrow()
                    Spacer()
                    Toggle(isOn: Binding(
                        get: { session.rest },
                        set: { state.setTodayRest($0) }
                    )) {
                        Text("Rest").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
                    }
                    .tint(Palette.red)
                    .fixedSize()
                }

                if session.rest {
                    Text("Rest day — recover well. 💤")
                        .font(.system(size: 14)).foregroundStyle(Palette.muted)
                } else if session.items.isEmpty {
                    Text("No exercises yet. Use the mic, add one, or set a weekly Workout Plan.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                } else {
                    ForEach(Array(session.items.enumerated()), id: \.offset) { idx, item in
                        workoutRow(idx, item)
                        if idx < session.items.count - 1 {
                            Divider().overlay(Palette.border)
                        }
                    }
                }
            }
        }
    }

    private func workoutRow(_ idx: Int, _ item: LoggedExercise) -> some View {
        let ex = state.exercisesById[item.exerciseId]
        let weighted = ex?.weighted ?? true
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button { if let ex { detail = ex } } label: {
                    HStack(spacing: 8) {
                        Text(ex?.icon ?? "🏋️").font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ex?.name ?? item.exerciseId)
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                                .lineLimit(2)
                            if let p = ex?.primary {
                                Text(p).font(.system(size: 11)).foregroundStyle(Palette.faint).lineLimit(1)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button { Haptics.tap(); state.toggleDone(index: idx) } label: {
                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(item.done ? Palette.ok : Palette.faint)
                }
            }
            HStack(spacing: 8) {
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

    private func qty(_ q: Double) -> String {
        q == q.rounded() ? String(Int(q)) : String(format: "%.1f", q)
    }
}
