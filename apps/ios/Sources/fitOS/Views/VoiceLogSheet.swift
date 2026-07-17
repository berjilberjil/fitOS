import SwiftUI

/// Speak a meal → transcribe on-device → parse via /api/voice/parse → review → log.
struct VoiceLogSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var voice = VoiceService()

    enum Phase { case listening, parsing, review, error }
    @State private var phase: Phase = .listening
    @State private var parsed: ParsedFoodLog?
    @State private var reviewMeal: MealKey = .breakfast
    @State private var quantities: [String: Double] = [:]
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
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { voice.stop(); dismiss() } } }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await begin() }
    }

    private var title: String {
        switch phase {
        case .listening: return "Listening…"
        case .parsing: return "Reading your meal…"
        case .review: return "Log this?"
        case .error: return "Voice log"
        }
    }

    // MARK: phases

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
                 ? "Say what you ate — e.g. “3 chapati and 100 ml milk for breakfast”."
                 : voice.transcript)
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Done") { finishListening() }
        }
    }

    private var parsing: some View {
        VStack(spacing: 18) {
            ProgressView().tint(Palette.red).padding(.top, 40)
            Text("“\(voice.transcript)”").font(.system(size: 14)).italic().foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var review: some View {
        let rows = matchedRows
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to").eyebrow()
                Picker("", selection: $reviewMeal) {
                    ForEach(MealKey.allCases) { Text($0.label).tag($0) }
                }.pickerStyle(.segmented)

                if rows.isEmpty {
                    Text("Nothing matched your foods. Try again, or add these in the Food tab.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                } else {
                    ForEach(rows) { row in
                        HStack(spacing: 12) {
                            Text(row.food.icon).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.food.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                                Text(row.food.servingLabel).font(.system(size: 11.5)).foregroundStyle(Palette.faint)
                            }
                            Spacer()
                            Stepper(value: Binding(
                                get: { quantities[row.id] ?? row.item.quantity },
                                set: { quantities[row.id] = max($0, 0) }), in: 0...50, step: 0.25) {
                                Text(fmt(quantities[row.id] ?? row.item.quantity))
                                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Palette.text)
                            }
                            .labelsHidden()
                            Text("×\(fmt(quantities[row.id] ?? row.item.quantity))")
                                .font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.muted).frame(width: 44)
                        }
                        .padding(.vertical, 6)
                        Divider().overlay(Palette.border)
                    }
                }

                let missing = unmatchedNames
                if !missing.isEmpty {
                    Text("Not in your foods: \(missing.joined(separator: ", ")) — add them in the Food tab.")
                        .font(.system(size: 12)).foregroundStyle(Palette.redBright)
                        .padding(10).background(Palette.redSoft).clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }

                HStack(spacing: 10) {
                    Button { restart() } label: {
                        Text("↻ Redo").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity).padding(.vertical, 14).background(Palette.surface2).clipShape(Capsule())
                    }
                    PrimaryButton(title: rows.isEmpty ? "Nothing to add" : "Add \(rows.count) to \(reviewMeal.label)") {
                        applyLog(rows)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var errorPane: some View {
        VStack(spacing: 16) {
            Text(errorMsg).font(.system(size: 14)).foregroundStyle(Palette.text).multilineTextAlignment(.center).padding(.top, 30)
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("Close").frame(maxWidth: .infinity).padding(.vertical, 14).foregroundStyle(Palette.muted)
                        .background(Palette.surface2).clipShape(Capsule())
                }
                PrimaryButton(title: "Try again") { restart() }
            }
        }
    }

    // MARK: logic

    private struct Row: Identifiable { let id: String; let item: ParsedItem; let food: Food }

    private var matchedRows: [Row] {
        (parsed?.items ?? []).compactMap { it in
            guard let fid = it.foodId, let food = state.foodsById[fid] else { return nil }
            return Row(id: it.id, item: it, food: food)
        }
    }
    private var unmatchedNames: [String] {
        (parsed?.items ?? []).filter { $0.foodId == nil || state.foodsById[$0.foodId!] == nil }.map(\.foodName)
    }

    private func begin() async {
        let ok = await voice.requestAuth()
        if ok { voice.start() }
        else { errorMsg = "fitOS needs microphone + speech access. Enable it in Settings → fitOS."; phase = .error }
    }

    private func finishListening() {
        voice.stop()
        let text = voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { errorMsg = "Didn't catch that — try again."; phase = .error; return }
        Task { await runParse(text) }
    }

    private func runParse(_ text: String) async {
        phase = .parsing
        guard let result = await state.parseVoice(transcript: text) else {
            errorMsg = "Couldn't understand that. Try again."; phase = .error; return
        }
        parsed = result
        reviewMeal = result.meal.flatMap { MealKey(rawValue: $0) } ?? guessMeal()
        quantities = Dictionary(result.items.map { ($0.id, $0.quantity) }, uniquingKeysWith: { a, _ in a })
        phase = .review
    }

    private func applyLog(_ rows: [Row]) {
        for row in rows {
            let q = quantities[row.id] ?? row.item.quantity
            if q > 0 { state.logFood(meal: reviewMeal, foodId: row.food.id, quantity: q) }
        }
        Haptics.success()
        dismiss()
    }

    private func restart() {
        parsed = nil; quantities = [:]; voice.transcript = ""; phase = .listening
        voice.start()
    }

    private func guessMeal() -> MealKey {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 11 { return .breakfast }
        if h < 16 { return .lunch }
        if h < 21 { return .dinner }
        return .snacks
    }

    private func fmt(_ q: Double) -> String { q == q.rounded() ? String(Int(q)) : String(format: "%.2f", q) }
}
