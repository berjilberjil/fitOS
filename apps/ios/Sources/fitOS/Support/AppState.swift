import Foundation
import SwiftUI

/// Single source of truth for the native app. Mirrors the web's synced-store
/// model: hydrate everything from /api/state on login, then push each changed
/// key back (debounced) — so web and iOS stay in lockstep on the same account.
@MainActor
final class AppState: ObservableObject {
    enum Phase { case loading, loggedOut, loggedIn }

    @Published var phase: Phase = .loading
    @Published var username = ""
    @Published var authError: String?
    @Published var isWorking = false

    @Published var profile: Profile = .default
    @Published var log: [String: DayLog] = [:]
    @Published var weightLog: [String: Double] = [:]
    @Published var customFoods: [Food] = []
    @Published var customExercises: [Exercise] = []
    @Published var catalogFoods: [Food] = []
    @Published var catalogExercises: [Exercise] = []

    @Published var workoutPlan: WorkoutWeekPlan = [:]
    @Published var workoutLog: [String: WorkoutDayLog] = [:]
    @Published var weekPlan: WeekPlan = [:]

    private let api = APIClient()
    private var pushTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Derived

    var allFoods: [Food] { catalogFoods + customFoods }
    var allExercises: [Exercise] { catalogExercises + customExercises }
    var foodsById: [String: Food] {
        Dictionary(allFoods.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }
    var exercisesById: [String: Exercise] {
        Dictionary(allExercises.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var todayKey: String { Self.dateKey(Date()) }
    var todayLog: DayLog? { log[todayKey] }
    var todayWeekday: Int { Self.weekday(of: todayKey) }

    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Weekday 0(Sun)..6(Sat) of a yyyy-MM-dd key — matches JS getDay().
    static func weekday(of key: String) -> Int {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return 0 }
        return Calendar(identifier: .gregorian).component(.weekday, from: d) - 1
    }

    // MARK: - Session lifecycle

    func bootstrap() async {
        do {
            let user = try await api.me()
            username = user.username
            await hydrate()
            phase = .loggedIn
        } catch {
            phase = .loggedOut
        }
    }

    func login(username u: String, password p: String) async {
        await authenticate { try await self.api.login(username: u, password: p) }
    }

    func register(username u: String, password p: String) async {
        await authenticate { try await self.api.register(username: u, password: p) }
    }

    private func authenticate(_ op: @escaping () async throws -> AuthUser) async {
        isWorking = true; authError = nil
        defer { isWorking = false }
        do {
            let user = try await op()
            username = user.username
            await hydrate()
            phase = .loggedIn
        } catch {
            authError = (error as? APIError)?.message ?? error.localizedDescription
        }
    }

    func logout() async {
        await api.logout()
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        profile = .default; log = [:]; weightLog = [:]
        customFoods = []; customExercises = []
        workoutPlan = [:]; workoutLog = [:]; weekPlan = [:]
        username = ""
        phase = .loggedOut
    }

    /// Pull catalog + all user state.
    func hydrate() async {
        async let catalogTask = try? api.catalog()
        async let stateTask = try? api.state()
        if let c = await catalogTask {
            catalogFoods = c.foods
            catalogExercises = c.exercises
        }
        if let s = await stateTask {
            profile = s.profile ?? .default
            log = s.log ?? [:]
            weightLog = s.weightlog ?? [:]
            customFoods = s.foods ?? []
            customExercises = s.exercises ?? []
            workoutPlan = s.workoutplan ?? [:]
            workoutLog = s.workoutlog ?? [:]
            weekPlan = s.weekplan ?? [:]
        }
    }

    // MARK: - Profile / weight

    func saveProfile(_ p: Profile) {
        var next = p; next.onboarded = true
        profile = next
        push("luxifit.profile", next)
    }

    func recordWeight(_ kg: Double, on date: Date = Date()) {
        let key = Self.dateKey(date)
        weightLog[key] = kg
        var p = profile; p.currentWeightKg = kg
        profile = p
        push("luxifit.weightlog", weightLog)
        push("luxifit.profile", p)
    }

    // MARK: - Food log (today)

    func logFood(meal: MealKey, foodId: String, quantity: Double) {
        var day = log[todayKey] ?? DayLog(date: todayKey, meals: [:])
        var items = day.meals[meal.rawValue] ?? []
        if let i = items.firstIndex(where: { $0.foodId == foodId }) {
            items[i].quantity += quantity
        } else {
            items.append(PlanItem(foodId: foodId, quantity: quantity))
        }
        day.meals[meal.rawValue] = items
        log[todayKey] = day
        push("luxifit.log", log)
    }

    func removeFood(meal: MealKey, foodId: String) {
        guard var day = log[todayKey] else { return }
        day.meals[meal.rawValue]?.removeAll { $0.foodId == foodId }
        if day.meals[meal.rawValue]?.isEmpty == true { day.meals[meal.rawValue] = nil }
        log[todayKey] = day
        push("luxifit.log", log)
    }

    // MARK: - Workout session (today) — progressive overload

    /// Most recent working weight for an exercise on any date before `beforeDate`.
    func lastWeight(exerciseId: String, before beforeDate: String) -> Double? {
        let dates = workoutLog.keys.filter { $0 < beforeDate }.sorted().reversed()
        for d in dates {
            if let hit = workoutLog[d]?.items.first(where: { $0.exerciseId == exerciseId && $0.weightKg > 0 }) {
                return hit.weightKg
            }
        }
        return nil
    }

    /// The day's session, seeded from the weekday routine the first time it's opened.
    func seededWorkoutDay(_ date: String) -> WorkoutDayLog {
        if let existing = workoutLog[date] {
            return WorkoutDayLog(date: date, rest: existing.rest, items: existing.items)
        }
        guard let routine = workoutPlan[String(Self.weekday(of: date))] else {
            return WorkoutDayLog(date: date, rest: false, items: [])
        }
        if routine.rest { return WorkoutDayLog(date: date, rest: true, items: []) }
        let items = routine.items.map { it in
            LoggedExercise(exerciseId: it.exerciseId, sets: it.sets, reps: it.reps,
                           weightKg: lastWeight(exerciseId: it.exerciseId, before: date) ?? 0, done: false)
        }
        return WorkoutDayLog(date: date, rest: false, items: items)
    }

    var todaySession: WorkoutDayLog { seededWorkoutDay(todayKey) }

    private func editToday(_ fn: (inout WorkoutDayLog) -> Void) {
        var day = seededWorkoutDay(todayKey)
        fn(&day)
        workoutLog[todayKey] = day
        push("luxifit.workoutlog", workoutLog)
    }

    private static func round2(_ n: Double) -> Double { max((n * 100).rounded() / 100, 0) }

    func bumpWeight(index: Int, delta: Double) {
        editToday { d in
            guard d.items.indices.contains(index) else { return }
            d.items[index].weightKg = Self.round2(d.items[index].weightKg + delta)
        }
    }
    func setLogSets(index: Int, _ sets: Int) {
        editToday { d in guard d.items.indices.contains(index) else { return }; d.items[index].sets = max(sets, 1) }
    }
    func setLogReps(index: Int, _ reps: Int) {
        editToday { d in guard d.items.indices.contains(index) else { return }; d.items[index].reps = max(reps, 1) }
    }
    func toggleDone(index: Int) {
        editToday { d in guard d.items.indices.contains(index) else { return }; d.items[index].done.toggle() }
    }
    func addExerciseToday(_ exerciseId: String) {
        editToday { d in
            d.rest = false
            d.items.append(LoggedExercise(exerciseId: exerciseId, sets: WorkoutDefaults.sets,
                reps: WorkoutDefaults.reps, weightKg: lastWeight(exerciseId: exerciseId, before: todayKey) ?? 0, done: false))
        }
    }
    func removeToday(index: Int) {
        editToday { d in guard d.items.indices.contains(index) else { return }; d.items.remove(at: index) }
    }
    func setTodayRest(_ rest: Bool) {
        editToday { d in d.rest = rest; if rest { d.items = [] } }
    }

    // MARK: - Workout plan (weekly routine)

    func planDay(_ weekday: Int) -> WorkoutDayPlan { workoutPlan[String(weekday)] ?? .empty }

    private func editPlan(_ weekday: Int, _ fn: (inout WorkoutDayPlan) -> Void) {
        var day = workoutPlan[String(weekday)] ?? .empty
        fn(&day)
        workoutPlan[String(weekday)] = day
        push("luxifit.workoutplan", workoutPlan)
    }
    func addPlanExercise(weekday: Int, exerciseId: String) {
        editPlan(weekday) { d in
            d.rest = false
            d.items.append(PlanExercise(exerciseId: exerciseId, sets: WorkoutDefaults.sets, reps: WorkoutDefaults.reps))
        }
    }
    func setPlanSets(weekday: Int, index: Int, _ sets: Int) {
        editPlan(weekday) { d in guard d.items.indices.contains(index) else { return }; d.items[index].sets = max(sets, 1) }
    }
    func setPlanReps(weekday: Int, index: Int, _ reps: Int) {
        editPlan(weekday) { d in guard d.items.indices.contains(index) else { return }; d.items[index].reps = max(reps, 1) }
    }
    func removePlanExercise(weekday: Int, index: Int) {
        editPlan(weekday) { d in guard d.items.indices.contains(index) else { return }; d.items.remove(at: index) }
    }
    func setRestDay(weekday: Int, _ rest: Bool) {
        editPlan(weekday) { d in d.rest = rest }
    }

    // MARK: - Meal plan (weekly)

    private static let emptyMeals: MealMap = ["breakfast": [], "lunch": [], "dinner": [], "snacks": []]
    func mealPlanDay(_ weekday: Int) -> MealMap { weekPlan[String(weekday)] ?? Self.emptyMeals }

    private func editMealPlan(_ weekday: Int, _ fn: (inout MealMap) -> Void) {
        var day = weekPlan[String(weekday)] ?? Self.emptyMeals
        fn(&day)
        weekPlan[String(weekday)] = day
        push("luxifit.weekplan", weekPlan)
    }
    func addPlanFood(weekday: Int, meal: MealKey, foodId: String, quantity: Double = 1) {
        editMealPlan(weekday) { d in d[meal.rawValue, default: []].append(PlanItem(foodId: foodId, quantity: quantity)) }
    }
    func setPlanFoodQty(weekday: Int, meal: MealKey, index: Int, _ quantity: Double) {
        editMealPlan(weekday) { d in
            guard var arr = d[meal.rawValue], arr.indices.contains(index) else { return }
            arr[index].quantity = max(quantity, 0); d[meal.rawValue] = arr
        }
    }
    func removePlanFood(weekday: Int, meal: MealKey, index: Int) {
        editMealPlan(weekday) { d in
            guard var arr = d[meal.rawValue], arr.indices.contains(index) else { return }
            arr.remove(at: index); d[meal.rawValue] = arr
        }
    }

    // MARK: - Push

    /// Debounced per-key push, matching the web's 350ms scheduler.
    private func push(_ key: String, _ value: Encodable) {
        pushTasks[key]?.cancel()
        pushTasks[key] = Task { [api] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            try? await api.putState(key, value)
        }
    }
}
