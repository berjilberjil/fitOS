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

    private let api = APIClient()
    private var pushTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Derived

    var allFoods: [Food] { catalogFoods + customFoods }
    var allExercises: [Exercise] { catalogExercises + customExercises }
    var foodsById: [String: Food] {
        Dictionary(allFoods.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var todayKey: String { Self.dateKey(Date()) }
    var todayLog: DayLog? { log[todayKey] }

    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
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
        }
    }

    // MARK: - Mutations (update local, push to server)

    func saveProfile(_ p: Profile) {
        var next = p; next.onboarded = true
        profile = next
        push("luxifit.profile", next)
    }

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

    func recordWeight(_ kg: Double, on date: Date = Date()) {
        let key = Self.dateKey(date)
        weightLog[key] = kg
        var p = profile; p.currentWeightKg = kg
        profile = p
        push("luxifit.weightlog", weightLog)
        push("luxifit.profile", p)
    }

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
