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
    @Published var catalogFoods: [Food] = []          // from /api/catalog (seed)
    @Published var catalogExercises: [Exercise] = []
    // luxifit.foods / luxifit.exercises hold the user's FULL list once they've
    // edited anything (web seeds them with the whole catalog). Empty => use catalog.
    @Published var userFoods: [Food] = []
    @Published var userExercises: [Exercise] = []
    @Published var exerciseMedia: [String: ExerciseMedia] = [:]
    @Published var anatomy: AnatomyData?
    @Published var anatomyError: String?

    @Published var workoutPlan: WorkoutWeekPlan = [:]
    @Published var workoutLog: [String: WorkoutDayLog] = [:]
    @Published var weekPlan: WeekPlan = [:]
    /// Daily progress photos — metadata in app_state; JPEG bytes in Cloudflare R2.
    @Published var progressPhotos: [ProgressPhoto] = []

    /// True only after a successful `/api/state` hydrate — blocks push so we never
    /// clobber server data with empty defaults after a failed load (matches web).
    private(set) var isHydrated = false
    @Published var lastSyncError: String?

    private let api = APIClient()
    private var pushTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Derived

    /// The user's list once edited, otherwise the shipped catalog.
    var allFoods: [Food] { userFoods.isEmpty ? catalogFoods : userFoods }
    var allExercises: [Exercise] {
        guard !userExercises.isEmpty else { return catalogExercises }
        let have = Set(userExercises.map(\.id))
        return userExercises + catalogExercises.filter { !have.contains($0.id) }
    }
    var foodsById: [String: Food] {
        Dictionary(allFoods.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }
    var exercisesById: [String: Exercise] {
        Dictionary(allExercises.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }
    func mediaFor(_ exerciseId: String) -> ExerciseMedia? { exerciseMedia[exerciseId] }

    var todayKey: String { Self.dateKey(Date()) }
    /// Today's log, seeded from the weekly meal plan when no entry exists yet
    /// (same contract as web `getOrSeedDay`).
    var todayLog: DayLog { dayLog(for: todayKey) }
    var todayWeekday: Int { Self.weekday(of: todayKey) }

    /// Web `getOrSeedDay` — planned meals become the starting log for a fresh date.
    func dayLog(for date: String) -> DayLog {
        if let existing = log[date] { return existing }
        return seedDayFromPlan(date)
    }

    private func seedDayFromPlan(_ date: String) -> DayLog {
        let routine = mealPlanDay(Self.weekday(of: date))
        var meals: [String: [PlanItem]] = [:]
        for meal in MealKey.allCases {
            meals[meal.rawValue] = (routine[meal.rawValue] ?? []).map {
                PlanItem(foodId: $0.foodId, quantity: $0.quantity)
            }
        }
        return DayLog(date: date, meals: meals)
    }

    /// Resolve editable day (seeds from plan if needed, then writes into `log`).
    private func editableDayLog(for date: String) -> DayLog {
        if let existing = log[date] { return existing }
        let seeded = seedDayFromPlan(date)
        return seeded
    }

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
            // Session is valid even if state pull failed — push stays gated by isHydrated.
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
            if !isHydrated {
                // Stay in app with banner; saves stay blocked until pull succeeds.
                lastHydrateError = lastHydrateError ?? "Couldn't load your data. Pull to retry."
            }
        } catch {
            authError = (error as? APIError)?.message ?? error.localizedDescription
        }
    }

    func logout() async {
        await api.logout()
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        profile = .default; log = [:]; weightLog = [:]
        userFoods = []; userExercises = []
        workoutPlan = [:]; workoutLog = [:]; weekPlan = [:]
        progressPhotos = []
        username = ""
        isHydrated = false
        lastSyncError = nil
        anatomy = nil
        anatomyError = nil
        phase = .loggedOut
    }

    /// Pull catalog + all user state. Safe to call again for pull-to-refresh.
    @Published var lastHydrateError: String?

    func hydrate() async {
        lastHydrateError = nil
        async let catalogOpt = try? api.catalog()
        async let stateOpt = try? api.state()
        let c = await catalogOpt
        let s = await stateOpt

        if let c {
            catalogFoods = c.foods
            catalogExercises = c.exercises
            exerciseMedia = c.media ?? [:]
        } else {
            lastHydrateError = "Couldn't load catalog. Pull to retry."
        }

        if let s {
            let rawProfile = s.profile ?? .default
            let rawWeightLog = s.weightlog ?? [:]
            let (cleanProfile, profileFixed) = Self.sanitizeProfile(rawProfile)
            let cleanWeightLog = Self.sanitizeWeightLog(rawWeightLog)
            let weightLogFixed = cleanWeightLog != rawWeightLog

            profile = cleanProfile
            log = s.log ?? [:]
            weightLog = cleanWeightLog
            userFoods = s.foods ?? []
            userExercises = s.exercises ?? []
            workoutPlan = s.workoutplan ?? [:]
            workoutLog = s.workoutlog ?? [:]
            weekPlan = s.weekplan ?? [:]
            progressPhotos = (s.progressPhotos ?? []).sorted { $0.createdAt > $1.createdAt }
            isHydrated = true
            lastSyncError = nil
            if c != nil { lastHydrateError = nil }

            // Persist clamps so a corrupted 494 kg entry cannot keep resurfacing.
            if profileFixed { push("luxifit.profile", cleanProfile) }
            if weightLogFixed { push("luxifit.weightlog", cleanWeightLog) }
        } else {
            // Do NOT mark hydrated — blocks push that would wipe server data.
            isHydrated = false
            if c != nil {
                lastHydrateError = "Couldn't load your data. Pull to retry."
            }
        }
    }

    func refresh() async {
        await hydrate()
    }

    /// Lazy-load the anatomy dataset the first time the Body view appears.
    func loadAnatomy() async {
        if anatomy != nil { return }
        anatomyError = nil
        do {
            anatomy = try await api.anatomy()
        } catch {
            anatomyError = (error as? APIError)?.message ?? error.localizedDescription
        }
    }

    // MARK: - Voice logging (unified food + workout)

    func plannedTodayFoodIds() -> [String] {
        let day = mealPlanDay(todayWeekday)
        return MealKey.allCases.flatMap { day[$0.rawValue] ?? [] }.map(\.foodId)
    }

    func plannedTodayExerciseIds() -> [String] {
        todaySession.items.map(\.exerciseId)
    }

    func parseVoiceUnified(transcript: String) async -> UnifiedVoiceParse? {
        let foods = allFoods.map { FoodLite(id: $0.id, name: $0.name, serving: $0.servingLabel) }
        let exs = allExercises.map { ExerciseLite(id: $0.id, name: $0.name, primary: $0.primary) }
        let req = VoiceParseRequest(
            transcript: transcript,
            foods: foods,
            exercises: exs,
            plannedFoodIds: plannedTodayFoodIds(),
            plannedExerciseIds: plannedTodayExerciseIds(),
            unified: true
        )
        return try? await api.parseVoice(req)
    }

    /// Apply voice food items to today's log (same merge logic as manual log).
    func applyVoiceFoods(meal: MealKey, items: [(foodId: String, quantity: Double)]) {
        for it in items where it.quantity > 0 {
            logFood(meal: meal, foodId: it.foodId, quantity: it.quantity)
        }
    }

    /// Apply voice workout items — add exercise if missing, set sets/reps/weight when given.
    func applyVoiceWorkouts(_ items: [ParsedWorkoutItem]) {
        for it in items {
            guard let eid = it.exerciseId, exercisesById[eid] != nil else { continue }
            var day = seededWorkoutDay(todayKey)
            day.rest = false
            if let idx = day.items.firstIndex(where: { $0.exerciseId == eid }) {
                if let s = it.sets { day.items[idx].sets = max(Int(s.rounded()), 1) }
                if let r = it.reps { day.items[idx].reps = max(Int(r.rounded()), 1) }
                if let w = it.weightKg { day.items[idx].weightKg = Self.round2(w) }
            } else {
                day.items.append(LoggedExercise(
                    exerciseId: eid,
                    sets: max(Int((it.sets ?? Double(WorkoutDefaults.sets)).rounded()), 1),
                    reps: max(Int((it.reps ?? Double(WorkoutDefaults.reps)).rounded()), 1),
                    weightKg: Self.round2(it.weightKg ?? lastWeight(exerciseId: eid, before: todayKey) ?? 0),
                    done: false
                ))
            }
            workoutLog[todayKey] = day
        }
        push("luxifit.workoutlog", workoutLog)
    }

    // MARK: - Profile / weight

    /// Plausible adult body-weight range (kg). Prevents runaway +/- steppers (e.g. 494 kg).
    static let bodyWeightMinKg = 30.0
    static let bodyWeightMaxKg = 250.0

    static func clampBodyWeight(_ kg: Double) -> Double {
        round2(min(max(kg, bodyWeightMinKg), bodyWeightMaxKg))
    }

    static func isPlausibleBodyWeight(_ kg: Double) -> Bool {
        kg.isFinite && kg >= bodyWeightMinKg && kg <= bodyWeightMaxKg
    }

    static func sanitizeWeightLog(_ log: [String: Double]) -> [String: Double] {
        var out: [String: Double] = [:]
        for (k, v) in log where isPlausibleBodyWeight(v) {
            out[k] = round2(v)
        }
        return out
    }

    /// Returns sanitized profile + whether anything was corrected.
    static func sanitizeProfile(_ p: Profile) -> (Profile, Bool) {
        var next = p
        var changed = false
        if !isPlausibleBodyWeight(next.currentWeightKg) {
            next.currentWeightKg = Profile.default.currentWeightKg
            changed = true
        } else {
            let c = clampBodyWeight(next.currentWeightKg)
            if c != next.currentWeightKg { next.currentWeightKg = c; changed = true }
        }
        if !isPlausibleBodyWeight(next.targetWeightKg) {
            next.targetWeightKg = next.currentWeightKg
            changed = true
        } else {
            let t = clampBodyWeight(next.targetWeightKg)
            if t != next.targetWeightKg { next.targetWeightKg = t; changed = true }
        }
        return (next, changed)
    }

    func saveProfile(_ p: Profile) {
        var next = p
        next.onboarded = true
        next.currentWeightKg = Self.clampBodyWeight(next.currentWeightKg)
        next.targetWeightKg = Self.clampBodyWeight(next.targetWeightKg)
        profile = next
        push("luxifit.profile", next)
    }

    func recordWeight(_ kg: Double, on date: Date = Date()) {
        let key = Self.dateKey(date)
        let rounded = Self.clampBodyWeight(kg)
        weightLog[key] = rounded
        var p = profile; p.currentWeightKg = rounded
        profile = p
        push("luxifit.weightlog", weightLog)
        push("luxifit.profile", p)
    }

    /// One-tap body-weight adjust for today (±0.25 kg). Clamped by `recordWeight`.
    func bumpBodyWeight(delta: Double) {
        let base = weightLog[todayKey] ?? profile.currentWeightKg
        recordWeight(base + delta)
    }

    // MARK: - Progress photos

    static let maxProgressPhotos = 40

    /// Upload JPEG to R2, then save metadata only in `luxifit.progressphotos`.
    func addProgressPhoto(jpegBase64: String, note: String? = nil, date: Date = Date()) async throws {
        guard isHydrated else {
            throw APIError(status: 0, message: "Not synced yet — pull to refresh before saving.")
        }
        let dateKey = Self.dateKey(date)
        let photo = try await api.uploadProgressPhoto(
            jpegBase64: jpegBase64,
            date: dateKey,
            note: note
        )
        // Never keep base64 in synced state once R2 has the bytes.
        var stored = photo
        stored.jpegBase64 = ""
        progressPhotos.insert(stored, at: 0)

        // Cap metadata list — drop oldest and best-effort delete their R2 objects.
        if progressPhotos.count > Self.maxProgressPhotos {
            let dropped = progressPhotos.suffix(from: Self.maxProgressPhotos)
            progressPhotos = Array(progressPhotos.prefix(Self.maxProgressPhotos))
            for old in dropped {
                if let key = old.key, !key.isEmpty {
                    Task { try? await api.deleteMedia(key: key) }
                }
            }
        }
        push("luxifit.progressphotos", progressPhotos)
    }

    func deleteProgressPhoto(id: String) {
        guard let photo = progressPhotos.first(where: { $0.id == id }) else { return }
        progressPhotos.removeAll { $0.id == id }
        push("luxifit.progressphotos", progressPhotos)
        if let key = photo.key, !key.isEmpty {
            Task { try? await api.deleteMedia(key: key) }
        }
    }

    func photos(on dateKey: String) -> [ProgressPhoto] {
        progressPhotos.filter { $0.date == dateKey }
    }

    // MARK: - Food log (today)

    func logFood(meal: MealKey, foodId: String, quantity: Double) {
        var day = editableDayLog(for: todayKey)
        var items = day.meals[meal.rawValue] ?? []
        // Match web: append a new line (merge only exact same food when already present
        // keeps iOS one-row UX; still safe with index-based remove).
        if let i = items.firstIndex(where: { $0.foodId == foodId }) {
            items[i].quantity += quantity
        } else {
            items.append(PlanItem(foodId: foodId, quantity: quantity))
        }
        day.meals[meal.rawValue] = items
        log[todayKey] = day
        push("luxifit.log", log)
    }

    func setFoodQty(meal: MealKey, index: Int, quantity: Double) {
        var day = editableDayLog(for: todayKey)
        guard var items = day.meals[meal.rawValue], items.indices.contains(index) else { return }
        items[index].quantity = max(quantity, 0)
        day.meals[meal.rawValue] = items
        log[todayKey] = day
        push("luxifit.log", log)
    }

    func removeFood(meal: MealKey, index: Int) {
        var day = editableDayLog(for: todayKey)
        guard var items = day.meals[meal.rawValue], items.indices.contains(index) else { return }
        items.remove(at: index)
        day.meals[meal.rawValue] = items
        log[todayKey] = day
        push("luxifit.log", log)
    }

    /// Back-compat helper used by older call sites.
    func removeFood(meal: MealKey, foodId: String) {
        var day = editableDayLog(for: todayKey)
        guard var items = day.meals[meal.rawValue] else { return }
        if let i = items.firstIndex(where: { $0.foodId == foodId }) {
            items.remove(at: i)
            day.meals[meal.rawValue] = items
            log[todayKey] = day
            push("luxifit.log", log)
        }
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

    // MARK: - Custom foods / exercises (edit the full list, persist luxifit.foods/exercises)

    private static func newId(_ prefix: String) -> String { "\(prefix)-" + UUID().uuidString.lowercased() }

    func saveFood(_ food: Food) {
        var f = food
        var list = allFoods
        if let i = list.firstIndex(where: { $0.id == f.id }) {
            list[i] = f
        } else {
            if f.id.isEmpty { f.id = Self.newId("food") }
            f.isDefault = false
            list.insert(f, at: 0)
        }
        userFoods = list
        push("luxifit.foods", list)
    }

    func deleteFood(id: String) {
        userFoods = allFoods.filter { $0.id != id }
        push("luxifit.foods", userFoods)
    }

    func saveExercise(_ exercise: Exercise) {
        var e = exercise
        var list = allExercises
        if let i = list.firstIndex(where: { $0.id == e.id }) {
            list[i] = e
        } else {
            if e.id.isEmpty { e.id = Self.newId("ex-custom") }
            e.isDefault = false
            list.insert(e, at: 0)
        }
        userExercises = list
        push("luxifit.exercises", list)
    }

    func deleteExercise(id: String) {
        userExercises = allExercises.filter { $0.id != id }
        push("luxifit.exercises", userExercises)
    }

    // MARK: - Push

    /// Debounced per-key push, matching the web's 350ms scheduler.
    /// No-ops until hydrate succeeds so empty defaults never wipe the server.
    private func push(_ key: String, _ value: Encodable) {
        guard isHydrated else {
            lastSyncError = "Not synced yet — pull to refresh before saving."
            return
        }
        pushTasks[key]?.cancel()
        pushTasks[key] = Task { [api] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            do {
                try await api.putState(key, value)
                await MainActor.run { self.lastSyncError = nil }
            } catch {
                let msg = (error as? APIError)?.message ?? error.localizedDescription
                await MainActor.run { self.lastSyncError = "Couldn't save \(key): \(msg)" }
            }
        }
    }
}
