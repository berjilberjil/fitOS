import SwiftUI

struct TodayView: View {
    @EnvironmentObject var state: AppState

    private var targets: Macros { Nutrition.macroTargets(state.profile) }
    private var eaten: Macros { Nutrition.consumed(day: state.todayLog, foodsById: state.foodsById) }

    var body: some View {
        Screen(title: "Today") {
            calorieCard
            macrosCard
            mealsCard
        }
    }

    private var calorieCard: some View {
        Card {
            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calories").eyebrow()
                        Text("\(Int(eaten.calories.rounded()))")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.text)
                        Text("of \(Int(targets.calories.rounded())) kcal · \(Int(max(0, targets.calories - eaten.calories).rounded())) left")
                            .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    MacroRing(value: eaten.calories, target: targets.calories,
                              label: "Intake", unit: "kcal", size: 96)
                }
            }
        }
    }

    private var macrosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Macros").eyebrow()
                MacroBar(label: "Protein", value: eaten.protein, target: targets.protein, tint: Palette.red)
                MacroBar(label: "Carbs", value: eaten.carbs, target: targets.carbs, tint: Palette.info)
                MacroBar(label: "Fats", value: eaten.fats, target: targets.fats, tint: Palette.warn)
            }
        }
    }

    private var mealsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today's meals").eyebrow()
                let day = state.todayLog
                if day == nil || day!.meals.values.allSatisfy(\.isEmpty) {
                    Text("Nothing logged yet. Add food from the Food tab.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                } else {
                    ForEach(MealKey.allCases) { meal in
                        let items = day?.meals[meal.rawValue] ?? []
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(meal.icon)  \(meal.label)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.muted)
                                ForEach(items, id: \.foodId) { item in
                                    if let f = state.foodsById[item.foodId] {
                                        HStack {
                                            Text("\(f.icon)  \(f.name)")
                                                .font(.system(size: 14)).foregroundStyle(Palette.text)
                                            Spacer()
                                            Text("×\(qty(item.quantity))")
                                                .font(.system(size: 13, design: .rounded))
                                                .foregroundStyle(Palette.faint)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func qty(_ q: Double) -> String {
        q == q.rounded() ? String(Int(q)) : String(format: "%.2f", q)
    }
}
