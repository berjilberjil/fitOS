import Foundation

/// Nutrition math — kept in lockstep with apps/web `src/lib/utils/nutrition.ts`
/// and TodayView (TDEE as calorie goal, protein = 1.8 g/kg).
enum Nutrition {
    /// Mifflin-St Jeor, rounded (matches web `bmr()`).
    static func bmr(_ p: Profile) -> Double {
        let base = 10 * p.currentWeightKg + 6.25 * p.heightCm - 5 * Double(p.age)
        let raw = p.sex == "female" ? base - 161 : base + 5
        return raw.rounded()
    }

    /// Activity-adjusted TDEE, rounded (matches web `tdee()`).
    static func tdee(_ p: Profile) -> Double { (bmr(p) * p.activity).rounded() }

    /// Calorie goal shown on Today — web uses plain TDEE (no cut/bulk offset).
    static func calorieTarget(_ p: Profile) -> Double { tdee(p) }

    /// Protein 1.8 g/kg (web `proteinGoal`); fats ~25% of cals; carbs fill remainder.
    static func macroTargets(_ p: Profile) -> Macros {
        let cals = calorieTarget(p)
        let protein = (1.8 * p.currentWeightKg).rounded()
        let fats = (cals * 0.25 / 9).rounded()
        let carbs = max(0, (cals - protein * 4 - fats * 9) / 4).rounded()
        return Macros(calories: cals, protein: protein, carbs: carbs, fiber: 30, fats: fats)
    }

    static func bmi(_ p: Profile) -> Double {
        let m = p.heightCm / 100
        guard m > 0 else { return 0 }
        return p.currentWeightKg / (m * m)
    }

    static func bmiLabel(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case ..<25: return "Healthy"
        case ..<30: return "Overweight"
        default: return "Obese"
        }
    }

    /// Sum a day's meals into total macros using a food lookup table.
    static func consumed(day: DayLog?, foodsById: [String: Food]) -> Macros {
        guard let day else { return .zero }
        var m = Macros.zero
        for (_, items) in day.meals {
            for it in items {
                guard let f = foodsById[it.foodId] else { continue }
                m.calories += f.perServing.calories * it.quantity
                m.protein += f.perServing.protein * it.quantity
                m.carbs += f.perServing.carbs * it.quantity
                m.fiber += f.perServing.fiber * it.quantity
                m.fats += f.perServing.fats * it.quantity
            }
        }
        return m
    }

    /// Calories implied by macros — digestible carbs at 4, fiber at 2 (matches web).
    static func caloriesFromMacros(protein: Double, carbs: Double, fiber: Double, fats: Double) -> Double {
        let digestible = max(carbs - fiber, 0)
        return (protein * 4 + fats * 9 + digestible * 4 + fiber * 2).rounded()
    }
}
