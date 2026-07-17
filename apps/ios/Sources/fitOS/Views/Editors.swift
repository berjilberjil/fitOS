import SwiftUI

/// Create or edit a food. Calories auto-compute from macros unless overridden.
struct FoodEditorSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    var editing: Food?

    @State private var name = ""
    @State private var icon = "🍽️"
    @State private var category = "other"
    @State private var serving = "1 serving"
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fiber = 0.0
    @State private var fats = 0.0
    @State private var vitamins = ""
    @State private var isJunk = false
    @State private var calOverride = ""

    private let categories = ["protein", "carb", "veg", "dairy", "fruit", "drink", "junk", "other"]
    private var autoCal: Double { Nutrition.caloriesFromMacros(protein: protein, carbs: carbs, fiber: fiber, fats: fats) }
    private var calories: Double { Double(calOverride) ?? autoCal }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Emoji", text: $icon)
                    TextField("Name (e.g. Chapati)", text: $name)
                    TextField("Serving (e.g. 1 chapati)", text: $serving)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                }
                Section("Macros (per serving)") {
                    numField("Protein (g)", $protein)
                    numField("Carbs (g)", $carbs)
                    numField("Fiber (g)", $fiber)
                    numField("Fats (g)", $fats)
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField(String(Int(autoCal)), text: $calOverride)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 90)
                    }
                    Text("Auto from macros: \(Int(autoCal)) kcal — leave blank to use it.")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Section {
                    TextField("Vitamins / notes (optional)", text: $vitamins)
                    Toggle("Mark as junk", isOn: $isJunk).tint(Palette.red)
                }
                Section {
                    Button { save() } label: {
                        Text(editing == nil ? "Add food" : "Save food")
                            .frame(maxWidth: .infinity).foregroundStyle(Palette.red).fontWeight(.semibold)
                    }
                    if let editing, !editing.isDefault {
                        Button(role: .destructive) { state.deleteFood(id: editing.id); dismiss() } label: {
                            Text("Delete").frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle(editing == nil ? "New food" : "Edit food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear(perform: seed)
    }

    private func seed() {
        guard let f = editing else { return }
        name = f.name; icon = f.icon; category = f.category; serving = f.servingLabel
        protein = f.perServing.protein; carbs = f.perServing.carbs
        fiber = f.perServing.fiber; fats = f.perServing.fats
        vitamins = f.vitamins ?? ""; isJunk = f.isJunk
        // Preserve stored calories (don't recompute and clobber seed data).
        calOverride = String(Int(f.perServing.calories.rounded()))
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var food = editing ?? Food(id: "", name: "", icon: "", category: "other",
                                   servingLabel: "", perServing: .zero, vitamins: nil,
                                   isJunk: false, isDefault: false)
        food.name = trimmed
        food.icon = icon.isEmpty ? "🍽️" : icon
        food.category = category
        food.servingLabel = serving.isEmpty ? "1 serving" : serving
        food.perServing = Macros(calories: calories, protein: protein, carbs: carbs, fiber: fiber, fats: fats)
        food.vitamins = vitamins.isEmpty ? nil : vitamins
        food.isJunk = isJunk
        state.saveFood(food)
        dismiss()
    }

    private func numField(_ label: String, _ v: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: v, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }
}

/// Create or edit a custom exercise.
struct ExerciseEditorSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    var editing: Exercise?

    @State private var name = ""
    @State private var icon = "🏋️"
    @State private var category = "chest"
    @State private var equipment = "Barbell"
    @State private var primary = ""
    @State private var weighted = true

    private let categories = ["chest", "back", "shoulders", "arms", "legs", "core", "cardio", "boxing"]
    private let equipments = ["Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Kettlebell", "Band", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Emoji", text: $icon)
                    TextField("Name", text: $name)
                    TextField("Target muscle (e.g. Upper chest)", text: $primary)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Picker("Equipment", selection: $equipment) {
                        ForEach(equipments, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Uses added weight", isOn: $weighted).tint(Palette.red)
                }
                Section {
                    Button { save() } label: {
                        Text(editing == nil ? "Add exercise" : "Save exercise")
                            .frame(maxWidth: .infinity).foregroundStyle(Palette.red).fontWeight(.semibold)
                    }
                    if let editing, !editing.isDefault {
                        Button(role: .destructive) { state.deleteExercise(id: editing.id); dismiss() } label: {
                            Text("Delete").frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle(editing == nil ? "New exercise" : "Edit exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear(perform: seed)
    }

    private func seed() {
        guard let e = editing else { return }
        name = e.name; icon = e.icon; category = e.category
        equipment = e.equipment; primary = e.primary; weighted = e.weighted
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var ex = editing ?? Exercise(id: "", name: "", icon: "", category: "chest",
                                     equipment: "Barbell", primary: "", weighted: true, isDefault: false)
        ex.name = trimmed
        ex.icon = icon.isEmpty ? "🏋️" : icon
        ex.category = category
        ex.equipment = equipment
        ex.primary = primary.isEmpty ? category.capitalized : primary
        ex.weighted = weighted
        state.saveExercise(ex)
        dismiss()
    }
}
