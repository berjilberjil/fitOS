import SwiftUI

/// Pick an exercise from the catalog (used by workout session + plan editor).
struct ExercisePickerSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    let onPick: (String) -> Void

    private var grouped: [(String, [Exercise])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? state.allExercises
            : state.allExercises.filter { $0.name.lowercased().contains(q) || $0.primary.lowercased().contains(q) }
        return Dictionary(grouping: list, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section {
                        ForEach(items) { ex in
                            Button {
                                onPick(ex.id); dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(ex.icon).font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.text)
                                        Text("\(ex.equipment) · \(ex.primary)").font(.system(size: 12)).foregroundStyle(Palette.faint)
                                    }
                                }
                            }
                            .listRowBackground(Palette.surface)
                        }
                    } header: { Text(category).eyebrow() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search exercises")

            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

/// Pick a food from the catalog (used by meal-plan editor).
struct FoodPickerSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    let onPick: (String) -> Void

    private var grouped: [(String, [Food])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? state.allFoods : state.allFoods.filter { $0.name.lowercased().contains(q) }
        return Dictionary(grouping: list, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section {
                        ForEach(items) { food in
                            Button {
                                onPick(food.id); dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(food.icon).font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.text)
                                        Text("\(food.servingLabel) · \(Int(food.perServing.calories)) kcal · P\(Int(food.perServing.protein)) · C\(Int(food.perServing.carbs)) · Fi\(Int(food.perServing.fiber)) · F\(Int(food.perServing.fats))")
                                            .font(.system(size: 11)).foregroundStyle(Palette.faint)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .listRowBackground(Palette.surface)
                        }
                    } header: { Text(category).eyebrow() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search foods")

            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

/// Horizontal Sun..Sat weekday selector used by the plan editors.
struct WeekdayPicker: View {
    @Binding var selected: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { d in
                Button {
                    selected = d
                } label: {
                    Text(WEEKDAYS_SHORT[d])
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected == d ? Palette.red : Palette.surface2)
                        .foregroundStyle(selected == d ? .white : Palette.muted)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                }
            }
        }
    }
}
