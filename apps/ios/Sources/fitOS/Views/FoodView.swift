import SwiftUI

struct FoodView: View {
    @EnvironmentObject var state: AppState
    @State private var search = ""
    @State private var selected: Food?

    private var filtered: [Food] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return state.allFoods }
        return state.allFoods.filter { $0.name.lowercased().contains(q) }
    }

    private var grouped: [(String, [Food])] {
        Dictionary(grouping: filtered, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, foods in
                    Section {
                        ForEach(foods) { food in
                            Button { selected = food } label: { row(food) }
                                .listRowBackground(Palette.surface)
                        }
                    } header: {
                        Text(category).eyebrow()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Food")
            .searchable(text: $search, prompt: "Search foods")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(item: $selected) { food in
            LogFoodSheet(food: food)
                .presentationDetents([.medium])
        }
    }

    private func row(_ f: Food) -> some View {
        HStack(spacing: 12) {
            Text(f.icon).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(f.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.text)
                Text("\(f.servingLabel) · \(Int(f.perServing.calories)) kcal · P\(Int(f.perServing.protein))")
                    .font(.system(size: 12)).foregroundStyle(Palette.faint)
            }
            Spacer()
            if f.isJunk {
                Text("junk").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.warn)
            }
        }
        .padding(.vertical, 2)
    }
}

struct LogFoodSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let food: Food

    @State private var meal: MealKey = .breakfast
    @State private var quantity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text(food.icon).font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
                    Text(food.servingLabel).font(.system(size: 13)).foregroundStyle(Palette.muted)
                }
            }

            Picker("Meal", selection: $meal) {
                ForEach(MealKey.allCases) { m in Text(m.label).tag(m) }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Servings").font(.system(size: 15)).foregroundStyle(Palette.muted)
                Spacer()
                Stepper(value: $quantity, in: 0.5...20, step: 0.5) {
                    Text(quantity == quantity.rounded() ? String(Int(quantity)) : String(format: "%.1f", quantity))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.text)
                }
            }

            Text("\(Int((food.perServing.calories * quantity).rounded())) kcal · "
                 + "P\(Int((food.perServing.protein * quantity).rounded())) "
                 + "C\(Int((food.perServing.carbs * quantity).rounded())) "
                 + "F\(Int((food.perServing.fats * quantity).rounded()))")
                .font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.faint)

            PrimaryButton(title: "Add to \(meal.label)") {
                state.logFood(meal: meal, foodId: food.id, quantity: quantity)
                dismiss()
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bg.ignoresSafeArea())
    }
}
