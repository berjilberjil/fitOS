import Foundation

// Codable mirrors of apps/web/src/lib/types.ts. Property names match the JSON
// field names exactly (camelCase), so no key-decoding strategy is needed.

struct Macros: Codable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fiber: Double
    var fats: Double

    static let zero = Macros(calories: 0, protein: 0, carbs: 0, fiber: 0, fats: 0)
}

struct Food: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var icon: String
    var category: String        // protein | carb | veg | dairy | fruit | drink | junk | other
    var servingLabel: String
    var perServing: Macros
    var vitamins: String?
    var isJunk: Bool
    var isDefault: Bool
}

struct Exercise: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var icon: String
    var category: String        // chest | back | shoulders | arms | legs | core | cardio | boxing
    var equipment: String
    var primary: String
    var weighted: Bool
    var isDefault: Bool
}

struct Profile: Codable, Equatable {
    var name: String?
    var age: Int
    var sex: String             // "male" | "female"
    var heightCm: Double
    var currentWeightKg: Double
    var targetWeightKg: Double
    var activity: Double        // Mifflin activity factor
    var onboarded: Bool

    static let `default` = Profile(
        name: nil, age: 21, sex: "male", heightCm: 170,
        currentWeightKg: 65, targetWeightKg: 65, activity: 1.375, onboarded: false
    )
}

struct PlanItem: Codable, Equatable {
    var foodId: String
    var quantity: Double
}

/// What was actually eaten on a date, grouped by meal key.
/// meals: Record<MealKey, PlanItem[]>  →  [String: [PlanItem]]
struct DayLog: Codable, Equatable {
    var date: String
    var meals: [String: [PlanItem]]
}

enum MealKey: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .breakfast: return "☀️"
        case .lunch: return "🍽️"
        case .dinner: return "🌙"
        case .snacks: return "🍎"
        }
    }
}

/// The whole /api/state payload, decoded by luxifit.* keys.
struct AppStatePayload: Decodable {
    var profile: Profile?
    var log: [String: DayLog]?
    var weightlog: [String: Double]?
    var foods: [Food]?
    var exercises: [Exercise]?

    enum CodingKeys: String, CodingKey {
        case profile = "luxifit.profile"
        case log = "luxifit.log"
        case weightlog = "luxifit.weightlog"
        case foods = "luxifit.foods"
        case exercises = "luxifit.exercises"
    }
}

struct Catalog: Decodable {
    var foods: [Food]
    var exercises: [Exercise]
}

struct AuthUser: Decodable {
    var id: Int
    var username: String
}
