import XCTest
@testable import fitOS

final class NutritionTests: XCTestCase {

    private func profile(
        sex: String = "male",
        age: Int = 25,
        height: Double = 175,
        weight: Double = 70,
        target: Double = 70,
        activity: Double = 1.375
    ) -> Profile {
        Profile(name: "T", age: age, sex: sex, heightCm: height,
                currentWeightKg: weight, targetWeightKg: target,
                activity: activity, onboarded: true)
    }

    // MARK: - BMR / TDEE

    func testBMR_male() {
        let p = profile(sex: "male", age: 25, height: 175, weight: 70)
        // 10*70 + 6.25*175 - 5*25 + 5 = 1673.75 → rounded 1674 (matches web)
        XCTAssertEqual(Nutrition.bmr(p), 1674, accuracy: 0.01)
    }

    func testBMR_female() {
        let p = profile(sex: "female", age: 25, height: 165, weight: 60)
        // 10*60 + 6.25*165 - 5*25 - 161 = 1345.25 → rounded 1345
        XCTAssertEqual(Nutrition.bmr(p), 1345, accuracy: 0.01)
    }

    func testTDEE_scalesWithActivity() {
        let p = profile(activity: 1.55)
        XCTAssertEqual(Nutrition.tdee(p), (Nutrition.bmr(p) * 1.55).rounded(), accuracy: 0.01)
    }

    // MARK: - Calorie targets (web Today = plain TDEE)

    func testCalorieTarget_equalsTDEE() {
        let p = profile(weight: 70, target: 70)
        XCTAssertEqual(Nutrition.calorieTarget(p), Nutrition.tdee(p), accuracy: 0.01)
    }

    func testCalorieTarget_ignoresCutBulkOffset_parityWithWeb() {
        // Web Today does not apply cut/bulk — target weight must not change goal.
        let cut = profile(weight: 80, target: 70)
        let bulk = profile(weight: 60, target: 70)
        XCTAssertEqual(Nutrition.calorieTarget(cut), Nutrition.tdee(cut), accuracy: 0.01)
        XCTAssertEqual(Nutrition.calorieTarget(bulk), Nutrition.tdee(bulk), accuracy: 0.01)
    }

    // MARK: - Macro targets

    func testMacroTargets_proteinIs1_8gPerKg_webParity() {
        let p = profile(weight: 70, target: 70)
        let m = Nutrition.macroTargets(p)
        // web proteinGoal(70) = Math.round(70 * 1.8) = 126
        XCTAssertEqual(m.protein, 126, accuracy: 0.01)
        XCTAssertEqual(m.fiber, 30, accuracy: 0.01)
        XCTAssertGreaterThan(m.carbs, 0)
        XCTAssertGreaterThan(m.fats, 0)
        XCTAssertEqual(m.calories, Nutrition.calorieTarget(p), accuracy: 0.01)
    }

    // MARK: - BMI

    func testBMI() {
        let p = profile(height: 175, weight: 70)
        // 70 / (1.75^2) = 22.857...
        XCTAssertEqual(Nutrition.bmi(p), 70 / (1.75 * 1.75), accuracy: 0.001)
    }

    func testBMI_zeroHeight() {
        var p = profile()
        p.heightCm = 0
        XCTAssertEqual(Nutrition.bmi(p), 0)
    }

    func testBMILabels() {
        XCTAssertEqual(Nutrition.bmiLabel(17), "Underweight")
        XCTAssertEqual(Nutrition.bmiLabel(22), "Healthy")
        XCTAssertEqual(Nutrition.bmiLabel(27), "Overweight")
        XCTAssertEqual(Nutrition.bmiLabel(32), "Obese")
        XCTAssertEqual(Nutrition.bmiLabel(18.5), "Healthy")
        XCTAssertEqual(Nutrition.bmiLabel(25), "Overweight")
        XCTAssertEqual(Nutrition.bmiLabel(30), "Obese")
    }

    // MARK: - Calories from macros

    func testCaloriesFromMacros_digestibleCarbs() {
        // P20 + F10 + digestible carbs (30-5=25)*4 + fiber 5*2 = 80 + 90 + 100 + 10 = 280
        let cals = Nutrition.caloriesFromMacros(protein: 20, carbs: 30, fiber: 5, fats: 10)
        XCTAssertEqual(cals, 280, accuracy: 0.01)
    }

    func testCaloriesFromMacros_fiberExceedsCarbs() {
        let cals = Nutrition.caloriesFromMacros(protein: 10, carbs: 2, fiber: 5, fats: 0)
        // digestible = 0; fiber still *2
        XCTAssertEqual(cals, 10 * 4 + 5 * 2, accuracy: 0.01)
    }

    // MARK: - Consumed

    func testConsumed_emptyDay() {
        XCTAssertEqual(Nutrition.consumed(day: nil, foodsById: [:]), .zero)
    }

    func testConsumed_sumsMealsWithQuantity() {
        let food = Food(
            id: "f1", name: "Egg", icon: "🥚", category: "protein",
            servingLabel: "1 egg",
            perServing: Macros(calories: 70, protein: 6, carbs: 1, fiber: 0, fats: 5),
            vitamins: nil, isJunk: false, isDefault: true
        )
        let day = DayLog(date: "2026-07-17", meals: [
            "breakfast": [PlanItem(foodId: "f1", quantity: 2)],
            "lunch": [PlanItem(foodId: "f1", quantity: 1)],
        ])
        let m = Nutrition.consumed(day: day, foodsById: ["f1": food])
        XCTAssertEqual(m.calories, 210, accuracy: 0.01)
        XCTAssertEqual(m.protein, 18, accuracy: 0.01)
        XCTAssertEqual(m.fats, 15, accuracy: 0.01)
    }

    func testConsumed_skipsUnknownFoodIds() {
        let day = DayLog(date: "2026-07-17", meals: [
            "snacks": [PlanItem(foodId: "missing", quantity: 3)]
        ])
        XCTAssertEqual(Nutrition.consumed(day: day, foodsById: [:]), .zero)
    }
}
