import SwiftUI

/// Shared mic for food + workout — one utterance can log meals, lifts, or both.
struct UnifiedVoiceLogSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var voice = VoiceService()

    enum Phase { case listening, parsing, review, error }
    @State private var phase: Phase = .listening
    @State private var parsed: UnifiedVoiceParse?
    @State private var reviewMeal: MealKey = LogFoodSheet.guessMeal()
    @State private var foodQty: [String: Double] = [:]
    @State private var errorMsg = ""

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .listening: listening
                case .parsing: parsing
                case .review: review
                case .error: errorPane
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Palette.bg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { voice.stop(); dismiss() }
                }
            }

        }
        .task { await begin() }
    }

    private var title: String {
        switch phase {
        case .listening: return "Listening…"
        case .parsing: return "Understanding…"
        case .review: return "Log this?"
        case .error: return "Voice log"
        }
    }

    private var listening: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(Palette.red, lineWidth: 2).frame(width: 92, height: 92)
                    .scaleEffect(voice.status == .listening ? 1.15 : 0.9)
                    .opacity(voice.status == .listening ? 0.4 : 0.9)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: voice.status)
                Image(systemName: "mic.fill").font(.system(size: 30)).foregroundStyle(Palette.red)
            }
            .padding(.top, 20)
            Text(voice.transcript.isEmpty
                 ? "Say food and/or workout — e.g. “2 idli for breakfast and 3 sets of bench press at 60 kilos”."
                 : voice.transcript)
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Done") { finishListening() }
        }
    }

    private var parsing: some View {
        VStack(spacing: 18) {
            ProgressView().tint(Palette.red).padding(.top, 40)
            Text("“\(voice.transcript)”")
                .font(.system(size: 14)).italic().foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var review: some View {
        let foods = matchedFoods
        let workouts = matchedWorkouts
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !foods.isEmpty {
                    Text("Food").eyebrow()
                    Picker("", selection: $reviewMeal) {
                        ForEach(MealKey.allCases) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)

                    ForEach(foods) { row in
                        HStack(spacing: 12) {
                            Text(row.food.icon).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.food.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                                Text(row.food.servingLabel).font(.system(size: 11.5)).foregroundStyle(Palette.faint)
                            }
                            Spacer()
                            Text("×\(fmt(foodQty[row.id] ?? row.item.quantity))")
                                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Palette.text)
                            Stepper("", value: Binding(
                                get: { foodQty[row.id] ?? row.item.quantity },
                                set: { foodQty[row.id] = max($0, 0) }
                            ), in: 0...50, step: 0.25).labelsHidden()
                        }
                        Divider().overlay(Palette.border)
                    }
                }

                if !workouts.isEmpty {
                    Text("Workout").eyebrow().padding(.top, foods.isEmpty ? 0 : 8)
                    ForEach(workouts) { w in
                        HStack(spacing: 10) {
                            ExerciseThumb(
                                still: (w.exerciseId).flatMap { state.mediaFor($0)?.still },
                                size: CGSize(width: 44, height: 44),
                                cornerRadius: 10
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(w.exerciseName)
                                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                                Text(workoutSummary(w))
                                    .font(.system(size: 12)).foregroundStyle(Palette.faint)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Divider().overlay(Palette.border)
                    }
                }

                if foods.isEmpty && workouts.isEmpty {
                    Text("Couldn't match food or exercises. Try again, or log manually.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                }

                let unmatchedFood = (parsed?.foods ?? []).filter { $0.foodId == nil || state.foodsById[$0.foodId!] == nil }.map(\.foodName)
                let unmatchedEx = (parsed?.workouts ?? []).filter { $0.exerciseId == nil || state.exercisesById[$0.exerciseId!] == nil }.map(\.exerciseName)
                if !unmatchedFood.isEmpty || !unmatchedEx.isEmpty {
                    Text("Not matched: \((unmatchedFood + unmatchedEx).joined(separator: ", "))")
                        .font(.system(size: 12)).foregroundStyle(Palette.redBright)
                        .padding(10).background(Palette.redSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }

                HStack(spacing: 10) {
                    Button { restart() } label: {
                        Text("↻ Redo").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Palette.surface2).clipShape(Capsule())
                    }
                    PrimaryButton(title: applyTitle(foods: foods.count, workouts: workouts.count)) {
                        apply(foods: foods, workouts: workouts)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var errorPane: some View {
        VStack(spacing: 16) {
            Text(errorMsg).font(.system(size: 14)).foregroundStyle(Palette.text)
                .multilineTextAlignment(.center).padding(.top, 30)
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("Close").frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundStyle(Palette.muted).background(Palette.surface2).clipShape(Capsule())
                }
                PrimaryButton(title: "Try again") { restart() }
            }
        }
    }

    // MARK: - rows

    private struct FoodRow: Identifiable {
        let id: String
        let item: ParsedItem
        let food: Food
    }

    private var matchedFoods: [FoodRow] {
        (parsed?.foods ?? []).compactMap { it in
            guard let fid = it.foodId, let food = state.foodsById[fid] else { return nil }
            return FoodRow(id: it.id, item: it, food: food)
        }
    }

    private var matchedWorkouts: [ParsedWorkoutItem] {
        (parsed?.workouts ?? []).filter { it in
            guard let eid = it.exerciseId else { return false }
            return state.exercisesById[eid] != nil
        }
    }

    // MARK: - actions

    private func begin() async {
        let ok = await voice.requestAuth()
        if ok { voice.start() }
        else {
            errorMsg = "fitOS needs microphone + speech access. Enable it in Settings → fitOS."
            phase = .error
        }
    }

    private func finishListening() {
        voice.stop()
        let text = voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { errorMsg = "Didn't catch that — try again."; phase = .error; return }
        Task { await runParse(text) }
    }

    private func runParse(_ text: String) async {
        phase = .parsing
        guard let result = await state.parseVoiceUnified(transcript: text) else {
            errorMsg = "Couldn't understand that. Try again."; phase = .error; return
        }
        parsed = result
        reviewMeal = result.meal.flatMap { MealKey(rawValue: $0) } ?? LogFoodSheet.guessMeal()
        foodQty = Dictionary(result.foods.map { ($0.id, $0.quantity) }, uniquingKeysWith: { a, _ in a })
        phase = .review
    }

    private func apply(foods: [FoodRow], workouts: [ParsedWorkoutItem]) {
        let foodPairs = foods.compactMap { row -> (foodId: String, quantity: Double)? in
            let q = foodQty[row.id] ?? row.item.quantity
            guard q > 0 else { return nil }
            return (row.food.id, q)
        }
        if !foodPairs.isEmpty {
            state.applyVoiceFoods(meal: reviewMeal, items: foodPairs)
        }
        if !workouts.isEmpty {
            state.applyVoiceWorkouts(workouts)
        }
        Haptics.success()
        dismiss()
    }

    private func restart() {
        parsed = nil; foodQty = [:]; voice.transcript = ""; phase = .listening
        voice.start()
    }

    private func applyTitle(foods: Int, workouts: Int) -> String {
        if foods == 0 && workouts == 0 { return "Nothing to add" }
        if foods > 0 && workouts > 0 { return "Add food + workout" }
        if workouts > 0 { return "Add \(workouts) exercise\(workouts == 1 ? "" : "s")" }
        return "Add \(foods) to \(reviewMeal.label)"
    }

    private func workoutSummary(_ w: ParsedWorkoutItem) -> String {
        var parts: [String] = []
        if let s = w.sets { parts.append("\(Int(s)) sets") }
        if let r = w.reps { parts.append("\(Int(r)) reps") }
        if let kg = w.weightKg { parts.append(String(format: kg == kg.rounded() ? "%.0f kg" : "%.1f kg", kg)) }
        return parts.isEmpty ? "Add to today's session" : parts.joined(separator: " · ")
    }

    private func fmt(_ q: Double) -> String {
        q == q.rounded() ? String(Int(q)) : String(format: "%.2f", q)
    }
}
