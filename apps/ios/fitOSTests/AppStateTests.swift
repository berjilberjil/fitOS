import XCTest
@testable import fitOS

@MainActor
final class AppStateTests: XCTestCase {
    var state: AppState!

    override func setUp() async throws {
        state = AppState()
        // Seed catalogs so food/exercise lookups work offline.
        state.catalogFoods = [
            Food(id: "egg", name: "Egg", icon: "🥚", category: "protein",
                 servingLabel: "1", perServing: Macros(calories: 70, protein: 6, carbs: 1, fiber: 0, fats: 5),
                 vitamins: nil, isJunk: false, isDefault: true),
            Food(id: "rice", name: "Rice", icon: "🍚", category: "carb",
                 servingLabel: "1 cup", perServing: Macros(calories: 200, protein: 4, carbs: 45, fiber: 1, fats: 1),
                 vitamins: nil, isJunk: false, isDefault: true),
        ]
        state.catalogExercises = [
            Exercise(id: "bench", name: "Bench", icon: "🏋️", category: "chest",
                     equipment: "Barbell", primary: "Chest", weighted: true, isDefault: true),
            Exercise(id: "squat", name: "Squat", icon: "🦵", category: "legs",
                     equipment: "Barbell", primary: "Quads", weighted: true, isDefault: true),
            Exercise(id: "plank", name: "Plank", icon: "🧘", category: "core",
                     equipment: "Bodyweight", primary: "Core", weighted: false, isDefault: true),
        ]
    }

    // MARK: - Date helpers

    func testDateKey_format() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let d = cal.date(from: DateComponents(year: 2026, month: 7, day: 17))!
        // dateKey uses local calendar — just assert format yyyy-MM-dd
        let key = AppState.dateKey(d)
        XCTAssertTrue(key.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil)
    }

    func testWeekday_knownSunday() {
        // 2026-07-12 is a Sunday
        XCTAssertEqual(AppState.weekday(of: "2026-07-12"), 0)
        // 2026-07-13 Monday
        XCTAssertEqual(AppState.weekday(of: "2026-07-13"), 1)
        // 2026-07-18 Saturday
        XCTAssertEqual(AppState.weekday(of: "2026-07-18"), 6)
    }

    func testWeekday_invalidKey() {
        XCTAssertEqual(AppState.weekday(of: "not-a-date"), 0)
    }

    // MARK: - Catalog merge

    func testAllFoods_usesCatalogWhenUserEmpty() {
        XCTAssertEqual(state.allFoods.count, 2)
        XCTAssertEqual(state.foodsById["egg"]?.name, "Egg")
    }

    func testAllFoods_userListReplacesCatalog() {
        state.userFoods = [
            Food(id: "custom", name: "Custom", icon: "🍽️", category: "other",
                 servingLabel: "1", perServing: .zero, vitamins: nil, isJunk: false, isDefault: false)
        ]
        XCTAssertEqual(state.allFoods.count, 1)
        XCTAssertEqual(state.allFoods[0].id, "custom")
    }

    func testAllExercises_mergesMissingFromCatalog() {
        state.userExercises = [
            Exercise(id: "custom-ex", name: "Custom", icon: "💪", category: "arms",
                     equipment: "Dumbbell", primary: "Biceps", weighted: true, isDefault: false)
        ]
        // custom + catalog ones not in user list
        let ids = Set(state.allExercises.map(\.id))
        XCTAssertTrue(ids.contains("custom-ex"))
        XCTAssertTrue(ids.contains("bench"))
        XCTAssertTrue(ids.contains("squat"))
    }

    // MARK: - Food log

    func testLogFood_addsAndMergesQuantity() {
        state.logFood(meal: .breakfast, foodId: "egg", quantity: 1)
        state.logFood(meal: .breakfast, foodId: "egg", quantity: 2)
        let items = state.todayLog.meals["breakfast"] ?? []
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].quantity, 3, accuracy: 0.001)
    }

    func testLogFood_separateMeals() {
        state.logFood(meal: .breakfast, foodId: "egg", quantity: 1)
        state.logFood(meal: .lunch, foodId: "rice", quantity: 1)
        XCTAssertEqual(state.todayLog.meals["breakfast"]?.count, 1)
        XCTAssertEqual(state.todayLog.meals["lunch"]?.count, 1)
    }

    func testRemoveFood() {
        state.logFood(meal: .dinner, foodId: "rice", quantity: 1)
        state.removeFood(meal: .dinner, foodId: "rice")
        let dinner = state.todayLog.meals["dinner"] ?? []
        XCTAssertTrue(dinner.isEmpty)
    }

    func testRemoveFood_noopWhenMissing() {
        state.removeFood(meal: .snacks, foodId: "nope")
        // Seeded empty day still returns a DayLog (plan seed), not nil.
        let snacks = state.todayLog.meals["snacks"] ?? []
        XCTAssertTrue(snacks.isEmpty)
    }

    func testTodayLog_seedsFromMealPlan() {
        let wd = state.todayWeekday
        state.addPlanFood(weekday: wd, meal: .breakfast, foodId: "egg", quantity: 2)
        // Clear any existing log entry so seed path runs
        state.log.removeValue(forKey: state.todayKey)
        let day = state.todayLog
        XCTAssertEqual(day.meals["breakfast"]?.count, 1)
        XCTAssertEqual(day.meals["breakfast"]?.first?.foodId, "egg")
        let q = day.meals["breakfast"]?.first?.quantity ?? -1
        XCTAssertEqual(q, 2, accuracy: 0.001)
    }


    // MARK: - Weight / profile

    func testRecordWeight_updatesLogAndProfile() {
        state.recordWeight(72.5)
        XCTAssertEqual(state.profile.currentWeightKg, 72.5, accuracy: 0.001)
        XCTAssertEqual(state.weightLog[state.todayKey] ?? -1, 72.5, accuracy: 0.001)
    }

    func testRecordWeight_clampsAbsurdValues() {
        state.recordWeight(494.25)
        XCTAssertEqual(state.profile.currentWeightKg, AppState.bodyWeightMaxKg, accuracy: 0.001)
        XCTAssertEqual(state.weightLog[state.todayKey] ?? -1, AppState.bodyWeightMaxKg, accuracy: 0.001)

        state.recordWeight(5)
        XCTAssertEqual(state.profile.currentWeightKg, AppState.bodyWeightMinKg, accuracy: 0.001)
    }

    func testBumpBodyWeight_stopsAtMax() {
        state.recordWeight(249.75)
        state.bumpBodyWeight(delta: 0.25)
        XCTAssertEqual(state.profile.currentWeightKg, 250.0, accuracy: 0.001)
        state.bumpBodyWeight(delta: 0.25)
        XCTAssertEqual(state.profile.currentWeightKg, 250.0, accuracy: 0.001)
    }

    func testSanitizeWeightLog_dropsCorruptedEntries() {
        let clean = AppState.sanitizeWeightLog([
            "2026-07-01": 72.5,
            "2026-07-02": 494.25,
            "2026-07-03": 10
        ])
        XCTAssertEqual(clean.count, 1)
        XCTAssertEqual(clean["2026-07-01"] ?? -1, 72.5, accuracy: 0.001)
    }

    func testSaveProfile_marksOnboarded() {
        var p = Profile.default
        p.name = "Berjil"
        p.onboarded = false
        state.saveProfile(p)
        XCTAssertTrue(state.profile.onboarded)
        XCTAssertEqual(state.profile.name, "Berjil")
    }

    // MARK: - Workout session

    func testSeededWorkoutDay_fromPlan() {
        let wd = String(state.todayWeekday)
        state.workoutPlan[wd] = WorkoutDayPlan(
            rest: false,
            items: [PlanExercise(exerciseId: "bench", sets: 4, reps: 8)]
        )
        // Clear any existing log so seed runs
        state.workoutLog.removeValue(forKey: state.todayKey)

        let session = state.todaySession
        XCTAssertFalse(session.rest)
        XCTAssertEqual(session.items.count, 1)
        XCTAssertEqual(session.items[0].exerciseId, "bench")
        XCTAssertEqual(session.items[0].sets, 4)
        XCTAssertEqual(session.items[0].reps, 8)
        XCTAssertFalse(session.items[0].done)
    }

    func testSeededWorkoutDay_restDay() {
        let wd = String(state.todayWeekday)
        state.workoutPlan[wd] = WorkoutDayPlan(rest: true, items: [])
        state.workoutLog.removeValue(forKey: state.todayKey)
        let session = state.todaySession
        XCTAssertTrue(session.rest)
        XCTAssertTrue(session.items.isEmpty)
    }

    func testAddExerciseToday_andToggleDone() {
        state.workoutLog.removeValue(forKey: state.todayKey)
        state.addExerciseToday("squat")
        XCTAssertEqual(state.todaySession.items.count, 1)
        state.toggleDone(index: 0)
        XCTAssertTrue(state.todaySession.items[0].done)
        state.toggleDone(index: 0)
        XCTAssertFalse(state.todaySession.items[0].done)
    }

    func testBumpWeight_andClampSetsReps() {
        state.workoutLog.removeValue(forKey: state.todayKey)
        state.addExerciseToday("bench")
        state.bumpWeight(index: 0, delta: 2.5)
        XCTAssertEqual(state.todaySession.items[0].weightKg, 2.5, accuracy: 0.001)

        state.setLogSets(index: 0, 0) // max(0,1) → 1
        XCTAssertEqual(state.todaySession.items[0].sets, 1)
        state.setLogReps(index: 0, 12)
        XCTAssertEqual(state.todaySession.items[0].reps, 12)
    }

    func testRemoveToday_andSetRestClearsItems() {
        state.workoutLog.removeValue(forKey: state.todayKey)
        state.addExerciseToday("plank")
        state.addExerciseToday("squat")
        state.removeToday(index: 0)
        XCTAssertEqual(state.todaySession.items.count, 1)
        state.setTodayRest(true)
        XCTAssertTrue(state.todaySession.rest)
        XCTAssertTrue(state.todaySession.items.isEmpty)
    }

    func testLastWeight_findsMostRecentBeforeDate() {
        state.workoutLog["2026-07-01"] = WorkoutDayLog(
            date: "2026-07-01", rest: false,
            items: [LoggedExercise(exerciseId: "bench", sets: 3, reps: 5, weightKg: 50, done: true)]
        )
        state.workoutLog["2026-07-10"] = WorkoutDayLog(
            date: "2026-07-10", rest: false,
            items: [LoggedExercise(exerciseId: "bench", sets: 3, reps: 5, weightKg: 55, done: true)]
        )
        XCTAssertEqual(state.lastWeight(exerciseId: "bench", before: "2026-07-17"), 55)
        XCTAssertEqual(state.lastWeight(exerciseId: "bench", before: "2026-07-05"), 50)
        XCTAssertNil(state.lastWeight(exerciseId: "bench", before: "2026-06-01"))
        XCTAssertNil(state.lastWeight(exerciseId: "unknown", before: "2026-07-17"))
    }

    // MARK: - Workout plan

    func testPlanCRUD() {
        state.addPlanExercise(weekday: 2, exerciseId: "squat")
        XCTAssertEqual(state.planDay(2).items.count, 1)
        state.setPlanSets(weekday: 2, index: 0, 5)
        state.setPlanReps(weekday: 2, index: 0, 6)
        XCTAssertEqual(state.planDay(2).items[0].sets, 5)
        XCTAssertEqual(state.planDay(2).items[0].reps, 6)
        state.removePlanExercise(weekday: 2, index: 0)
        XCTAssertTrue(state.planDay(2).items.isEmpty)
        state.setRestDay(weekday: 2, true)
        XCTAssertTrue(state.planDay(2).rest)
    }

    // MARK: - Meal plan

    func testMealPlanCRUD() {
        state.addPlanFood(weekday: 3, meal: .lunch, foodId: "rice", quantity: 1.5)
        XCTAssertEqual(state.mealPlanDay(3)["lunch"]?.count, 1)
        state.setPlanFoodQty(weekday: 3, meal: .lunch, index: 0, 2)
        let qty = state.mealPlanDay(3)["lunch"]?[0].quantity ?? -1
        XCTAssertEqual(qty, 2, accuracy: 0.001)
        state.removePlanFood(weekday: 3, meal: .lunch, index: 0)
        XCTAssertTrue(state.mealPlanDay(3)["lunch"]?.isEmpty ?? true)
    }

    // MARK: - Custom food / exercise CRUD

    func testSaveAndDeleteCustomFood() {
        let f = Food(id: "", name: "Idli", icon: "🫓", category: "carb",
                     servingLabel: "1", perServing: Macros(calories: 40, protein: 1, carbs: 8, fiber: 0, fats: 0),
                     vitamins: nil, isJunk: false, isDefault: false)
        state.saveFood(f)
        XCTAssertTrue(state.allFoods.contains { $0.name == "Idli" })
        let id = state.allFoods.first { $0.name == "Idli" }!.id
        XCTAssertTrue(id.hasPrefix("food-"))
        state.deleteFood(id: id)
        XCTAssertFalse(state.allFoods.contains { $0.id == id })
    }

    func testSaveAndDeleteCustomExercise() {
        let e = Exercise(id: "", name: "Face pull", icon: "💪", category: "shoulders",
                         equipment: "Cable", primary: "Rear delts", weighted: true, isDefault: false)
        state.saveExercise(e)
        let id = state.allExercises.first { $0.name == "Face pull" }!.id
        XCTAssertTrue(id.hasPrefix("ex-custom"))
        state.deleteExercise(id: id)
        XCTAssertFalse(state.userExercises.contains { $0.id == id })
    }

    func testEditExistingFoodInCatalogCopiesFullList() {
        // First edit seeds userFoods with full list
        var egg = state.foodsById["egg"]!
        egg.name = "Egg (edited)"
        state.saveFood(egg)
        XCTAssertEqual(state.userFoods.count, state.catalogFoods.count)
        XCTAssertEqual(state.foodsById["egg"]?.name, "Egg (edited)")
    }

    // MARK: - Media lookup

    func testMediaFor() {
        state.exerciseMedia["bench"] = ExerciseMedia(gif: "g", still: "s")
        XCTAssertEqual(state.mediaFor("bench")?.still, "s")
        XCTAssertNil(state.mediaFor("nope"))
    }

    // MARK: - Voice planned ids

    func testPlannedTodayFoodIds() {
        let wd = state.todayWeekday
        state.addPlanFood(weekday: wd, meal: .breakfast, foodId: "egg")
        state.addPlanFood(weekday: wd, meal: .lunch, foodId: "rice")
        let ids = state.plannedTodayFoodIds()
        XCTAssertTrue(ids.contains("egg"))
        XCTAssertTrue(ids.contains("rice"))
    }
}
