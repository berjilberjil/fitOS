import XCTest
@testable import fitOS

final class ModelsTests: XCTestCase {

    // MARK: - MealKey

    func testMealKey_allCasesAndLabels() {
        XCTAssertEqual(MealKey.allCases.map(\.rawValue),
                       ["breakfast", "lunch", "dinner", "snacks"])
        XCTAssertEqual(MealKey.breakfast.label, "Breakfast")
        XCTAssertEqual(MealKey.snacks.label, "Snacks")
        XCTAssertFalse(MealKey.lunch.icon.isEmpty)
    }

    // MARK: - Weekdays

    func testWeekdayArrays_count7() {
        XCTAssertEqual(WEEKDAYS_SHORT.count, 7)
        XCTAssertEqual(WEEKDAYS_LONG.count, 7)
        XCTAssertEqual(WEEKDAYS_SHORT[0], "Sun")
        XCTAssertEqual(WEEKDAYS_LONG[1], "Monday")
    }

    // MARK: - Defaults

    func testProfileDefault() {
        let p = Profile.default
        XCTAssertEqual(p.age, 21)
        XCTAssertEqual(p.sex, "male")
        XCTAssertFalse(p.onboarded)
    }

    func testMacrosZero() {
        XCTAssertEqual(Macros.zero.calories, 0)
        XCTAssertEqual(Macros.zero.protein, 0)
    }

    func testWorkoutDefaults() {
        XCTAssertEqual(WorkoutDefaults.sets, 3)
        XCTAssertEqual(WorkoutDefaults.reps, 10)
        XCTAssertEqual(WorkoutDefaults.weightStep, 0.5)
    }

    // MARK: - Codable round-trips

    func testFood_roundTrip() throws {
        let f = Food(
            id: "chapati", name: "Chapati", icon: "🫓", category: "carb",
            servingLabel: "1 chapati",
            perServing: Macros(calories: 120, protein: 3, carbs: 20, fiber: 2, fats: 3),
            vitamins: "B1", isJunk: false, isDefault: true
        )
        let data = try JSONEncoder().encode(f)
        let decoded = try JSONDecoder().decode(Food.self, from: data)
        XCTAssertEqual(decoded, f)
    }

    func testExercise_roundTrip() throws {
        let e = Exercise(
            id: "bench", name: "Bench press", icon: "🏋️", category: "chest",
            equipment: "Barbell", primary: "Chest", weighted: true, isDefault: true
        )
        let data = try JSONEncoder().encode(e)
        let decoded = try JSONDecoder().decode(Exercise.self, from: data)
        XCTAssertEqual(decoded, e)
    }

    func testDayLog_roundTrip() throws {
        let day = DayLog(date: "2026-07-17", meals: [
            "breakfast": [PlanItem(foodId: "egg", quantity: 2.5)]
        ])
        let data = try JSONEncoder().encode(day)
        let decoded = try JSONDecoder().decode(DayLog.self, from: data)
        XCTAssertEqual(decoded, day)
    }

    func testWorkoutDayLog_roundTrip() throws {
        let log = WorkoutDayLog(
            date: "2026-07-17", rest: false,
            items: [LoggedExercise(exerciseId: "squat", sets: 3, reps: 8, weightKg: 60.5, done: true)]
        )
        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(WorkoutDayLog.self, from: data)
        XCTAssertEqual(decoded, log)
    }

    func testAppStatePayload_codingKeys() throws {
        let json = """
        {
          "luxifit.profile": {
            "age": 30, "sex": "female", "heightCm": 160,
            "currentWeightKg": 55, "targetWeightKg": 52,
            "activity": 1.2, "onboarded": true
          },
          "luxifit.weightlog": { "2026-01-01": 55.5 },
          "luxifit.log": {},
          "luxifit.workoutplan": {
            "1": { "rest": true, "items": [] }
          }
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder().decode(AppStatePayload.self, from: json)
        XCTAssertEqual(payload.profile?.age, 30)
        XCTAssertEqual(payload.profile?.sex, "female")
        XCTAssertEqual(payload.weightlog?["2026-01-01"], 55.5)
        XCTAssertEqual(payload.workoutplan?["1"]?.rest, true)
        XCTAssertNil(payload.foods)
    }

    func testCatalog_decodeWithMedia() throws {
        let json = """
        {
          "foods": [],
          "exercises": [{
            "id": "x", "name": "Push-up", "icon": "💪", "category": "chest",
            "equipment": "Bodyweight", "primary": "Chest", "weighted": false, "isDefault": true
          }],
          "media": {
            "x": { "gif": "https://example.com/a.gif", "still": "https://example.com/a.jpg" }
          }
        }
        """.data(using: .utf8)!
        let c = try JSONDecoder().decode(Catalog.self, from: json)
        XCTAssertEqual(c.exercises.count, 1)
        XCTAssertEqual(c.media?["x"]?.still, "https://example.com/a.jpg")
    }

    func testParsedFoodLog_identifiableItems() throws {
        let json = """
        {
          "meal": "lunch",
          "items": [
            { "spoken": "2 eggs", "foodId": "egg", "foodName": "Egg", "quantity": 2 },
            { "spoken": "rice", "foodId": null, "foodName": "Rice", "quantity": 1 }
          ]
        }
        """.data(using: .utf8)!
        let p = try JSONDecoder().decode(ParsedFoodLog.self, from: json)
        XCTAssertEqual(p.meal, "lunch")
        XCTAssertEqual(p.items.count, 2)
        XCTAssertEqual(p.items[0].foodId, "egg")
        XCTAssertNil(p.items[1].foodId)
        XCTAssertNotEqual(p.items[0].id, p.items[1].id)
    }

    func testAuthUser_decode() throws {
        let json = #"{"id": 7, "username": "berjil"}"#.data(using: .utf8)!
        let u = try JSONDecoder().decode(AuthUser.self, from: json)
        XCTAssertEqual(u.id, 7)
        XCTAssertEqual(u.username, "berjil")
    }
}
