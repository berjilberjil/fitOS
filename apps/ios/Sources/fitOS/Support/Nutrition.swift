import Foundation

/// Nutrition math. Mifflin-St Jeor TDEE is exact; the calorie/macro *targets*
/// use standard defaults — reconcile with apps/web TodayView if the web app
/// derives them differently, so both platforms show the same numbers.
enum Nutrition {
    static func bmr(_ p: Profile) -> Double {
        let base = 10 * p.currentWeightKg + 6.25 * p.heightCm - 5 * Double(p.age)
        return p.sex == "female" ? base - 161 : base + 5
    }

    static func tdee(_ p: Profile) -> Double { bmr(p) * p.activity }

    static func calorieTarget(_ p: Profile) -> Double {
        let t = tdee(p)
        if p.targetWeightKg < p.currentWeightKg - 0.5 { return (t - 400).rounded() } // cut
        if p.targetWeightKg > p.currentWeightKg + 0.5 { return (t + 300).rounded() } // bulk
        return t.rounded()
    }

    static func macroTargets(_ p: Profile) -> Macros {
        let cals = calorieTarget(p)
        let protein = (2.0 * p.currentWeightKg).rounded()
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
}
