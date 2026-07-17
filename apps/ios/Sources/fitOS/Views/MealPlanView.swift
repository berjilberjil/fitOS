import SwiftUI

/// Weekly meal plan editor — pick a weekday, add planned foods per meal.
struct MealPlanView: View {
    @EnvironmentObject var state: AppState
    @State private var weekday = AppState.weekday(of: AppState.dateKey(Date()))
    @State private var pickingMeal: MealKey?

    var body: some View {
        let day = state.mealPlanDay(weekday)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                WeekdayPicker(selected: $weekday)

                Card {
                    HStack {
                        Text("Planned intake").eyebrow()
                        Spacer()
                        Text("\(Int(dayCalories(day).rounded())) kcal")
                            .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Palette.red)
                    }
                }

                ForEach(MealKey.allCases) { meal in
                    mealSection(meal, items: day[meal.rawValue] ?? [])
                }
            }
            .padding(16)
        }
        .background(Palette.bg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $pickingMeal) { meal in
            FoodPickerSheet { foodId in
                state.addPlanFood(weekday: weekday, meal: meal, foodId: foodId)
            }
        }
    }

    private func mealSection(_ meal: MealKey, items: [PlanItem]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(meal.icon)  \(meal.label)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                    Spacer()
                    Button { pickingMeal = meal } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundStyle(Palette.red)
                    }
                }
                if items.isEmpty {
                    Text("Nothing planned").font(.system(size: 12)).foregroundStyle(Palette.faint)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                        let f = state.foodsById[item.foodId]
                        HStack(spacing: 8) {
                            Text("\(f?.icon ?? "❓")  \(f?.name ?? item.foodId)")
                                .font(.system(size: 14))
                                .foregroundStyle(f == nil ? Palette.warn : Palette.text)
                                .lineLimit(2)
                            Spacer(minLength: 4)
                            Text("×\(fmtQty(item.quantity))")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Palette.faint)
                                .monospacedDigit()
                            Stepper("", value: Binding(
                                get: { item.quantity },
                                set: { state.setPlanFoodQty(weekday: weekday, meal: meal, index: idx, $0) }
                            ), in: 0.5...50, step: 0.5)
                            .labelsHidden()
                            .fixedSize()
                            Button(role: .destructive) {
                                state.removePlanFood(weekday: weekday, meal: meal, index: idx)
                            } label: {
                                Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(Palette.faint)
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayCalories(_ day: MealMap) -> Double {
        var total = 0.0
        for (_, items) in day {
            for it in items { if let f = state.foodsById[it.foodId] { total += f.perServing.calories * it.quantity } }
        }
        return total
    }

    private func fmtQty(_ q: Double) -> String { q == q.rounded() ? String(Int(q)) : String(format: "%.1f", q) }
}
