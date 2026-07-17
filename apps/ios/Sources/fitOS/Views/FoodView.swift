import SwiftUI

/// Food tab: Log (browse + add to today) / weekly meal Plan.
struct FoodView: View {
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Log").tag(0)
                    Text("Plan").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .onChange(of: tab) { _ in Haptics.selection() }

                // Keep both segments mounted so Log ↔ Plan doesn't jump.
                ZStack(alignment: .top) {
                    FoodCatalog()
                        .opacity(tab == 0 ? 1 : 0)
                        .allowsHitTesting(tab == 0)
                        .accessibilityHidden(tab != 0)
                    MealPlanView()
                        .opacity(tab == 1 ? 1 : 0)
                        .allowsHitTesting(tab == 1)
                        .accessibilityHidden(tab != 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.bg)
            .navigationTitle("Food")

            .accessibilityIdentifier("screen.food")
        }
        .transaction { $0.animation = nil }
    }
}

/// Browse/search the catalog and log a food to today.
/// Inline search (not `.searchable`) so segment switches don't thrash the nav bar.
struct FoodCatalog: View {
    @EnvironmentObject var state: AppState
    @State private var search = ""
    @State private var selected: Food?
    @State private var editingFood: Food?
    @State private var newFood = false
    @State private var showVoice = false

    private var grouped: [(String, [Food])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? state.allFoods : state.allFoods.filter { $0.name.lowercased().contains(q) }
        return Dictionary(grouping: list, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Palette.faint)
                    TextField("Search foods", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Palette.text)
                    if !search.isEmpty {
                        Button { search = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.faint)
                        }
                    }
                    Button { Haptics.tap(); showVoice = true } label: {
                        Image(systemName: "mic.fill").foregroundStyle(Palette.red)
                    }
                    Button { newFood = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.red)
                    }
                }
                .listRowBackground(Palette.surface2)
                .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
            }

            ForEach(grouped, id: \.0) { category, foods in
                Section {
                    ForEach(foods) { food in
                        Button {
                            Haptics.soft()
                            selected = food
                        } label: { row(food) }
                            .listRowBackground(Palette.surface)
                            .contextMenu {
                                Button {
                                    Haptics.soft()
                                    selected = food
                                } label: { Label("Log to today", systemImage: "plus") }
                                Button {
                                    Haptics.soft()
                                    editingFood = food
                                } label: { Label("Edit food", systemImage: "pencil") }
                            }
                    }
                } header: { Text(category).eyebrow() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $selected) { food in
            LogFoodSheet(food: food).presentationDetents([.medium, .large])
        }
        .sheet(item: $editingFood) { FoodEditorSheet(editing: $0) }
        .sheet(isPresented: $newFood) { FoodEditorSheet(editing: nil) }
        .sheet(isPresented: $showVoice) { UnifiedVoiceLogSheet() }
    }

    /// Primary: P / C / Fiber / Fats. Secondary: vitamins & other notes.
    private func row(_ f: Food) -> some View {
        let m = f.perServing
        return HStack(alignment: .top, spacing: 12) {
            Text(f.icon).font(.system(size: 22)).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(f.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)
                    if f.isJunk {
                        Text("junk")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.warn)
                    }
                }
                Text("\(f.servingLabel)  ·  \(Int(m.calories.rounded())) kcal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.muted)

                // Main macros
                HStack(spacing: 8) {
                    macroChip("P", m.protein, Palette.red)
                    macroChip("C", m.carbs, Palette.info)
                    macroChip("Fi", m.fiber, Palette.ok)
                    macroChip("F", m.fats, Palette.warn)
                }

                if let v = f.vitamins, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(v)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.faint)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func macroChip(_ label: String, _ grams: Double, _ tint: Color) -> some View {
        Text("\(label)\(Int(grams.rounded()))")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .monospacedDigit()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}

/// Sheet: choose meal + servings, then log to today's food log.
struct LogFoodSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let food: Food

    @State private var meal: MealKey = LogFoodSheet.guessMeal()
    @State private var quantity: Double = 1

    /// Time-of-day default meal (same idea as voice log).
    static func guessMeal() -> MealKey {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 11 { return .breakfast }
        if h < 16 { return .lunch }
        if h < 21 { return .dinner }
        return .snacks
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Text(food.icon).font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(food.servingLabel).font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 0)
                }

                Picker("Meal", selection: $meal) {
                    ForEach(MealKey.allCases) { m in Text(m.label).tag(m) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("logFood.meal")

                HStack {
                    Text("Servings").font(.system(size: 15)).foregroundStyle(Palette.muted)
                    Spacer()
                    Stepper(value: $quantity, in: 0.5...20, step: 0.5) {
                        Text(quantity == quantity.rounded() ? String(Int(quantity)) : String(format: "%.1f", quantity))
                            .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(Palette.text)
                    }
                    .accessibilityIdentifier("logFood.servings")
                }

                let q = quantity
                let m = food.perServing
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int((m.calories * q).rounded())) kcal")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.text)
                    HStack(spacing: 10) {
                        logMacro("Protein", m.protein * q, Palette.red)
                        logMacro("Carbs", m.carbs * q, Palette.info)
                        logMacro("Fiber", m.fiber * q, Palette.ok)
                        logMacro("Fats", m.fats * q, Palette.warn)
                    }
                    if let v = food.vitamins, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(v)
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.faint)
                    }
                }

                PrimaryButton(title: "Add to \(meal.label)") {
                    state.logFood(meal: meal, foodId: food.id, quantity: quantity)
                    Haptics.success()
                    dismiss()
                }
                .accessibilityIdentifier("logFood.add")
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.bg.ignoresSafeArea())
            .navigationTitle("Log food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }

        }
        .accessibilityIdentifier("sheet.logFood")
    }

    private func logMacro(_ label: String, _ grams: Double, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.faint)
            Text("\(Int(grams.rounded()))g")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
