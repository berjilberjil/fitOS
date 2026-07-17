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
struct DayLog: Codable, Equatable {
    var date: String
    var meals: [String: [PlanItem]]
}

// ---------------- Workout ----------------

struct PlanExercise: Codable, Equatable {
    var exerciseId: String
    var sets: Int
    var reps: Int
}

/// A weekday's planned routine.
struct WorkoutDayPlan: Codable, Equatable {
    var rest: Bool
    var items: [PlanExercise]
    static let empty = WorkoutDayPlan(rest: false, items: [])
}

/// What was actually trained on a date — carries working weight for overload.
struct LoggedExercise: Codable, Equatable {
    var exerciseId: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var done: Bool
}

struct WorkoutDayLog: Codable, Equatable {
    var date: String
    var rest: Bool
    var items: [LoggedExercise]
}

/// Weekly routines are Record<weekday(0-6), …> → JSON object with string keys.
typealias WorkoutWeekPlan = [String: WorkoutDayPlan]
typealias MealMap = [String: [PlanItem]]
typealias WeekPlan = [String: MealMap]

enum WorkoutDefaults {
    static let sets = 3
    static let reps = 10
    static let weightStep = 0.5
}

// ---------------- Meals ----------------

enum MealKey: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snacks: return "🍿"
        }
    }
}

let WEEKDAYS_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
let WEEKDAYS_LONG = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

// ---------------- API payloads ----------------

/// The whole /api/state payload, decoded by luxifit.* keys (data contract).
struct AppStatePayload: Decodable {
    var profile: Profile?
    var log: [String: DayLog]?
    var weightlog: [String: Double]?
    var foods: [Food]?
    var exercises: [Exercise]?
    var workoutplan: WorkoutWeekPlan?
    var workoutlog: [String: WorkoutDayLog]?
    var weekplan: WeekPlan?

    enum CodingKeys: String, CodingKey {
        case profile = "luxifit.profile"
        case log = "luxifit.log"
        case weightlog = "luxifit.weightlog"
        case foods = "luxifit.foods"
        case exercises = "luxifit.exercises"
        case workoutplan = "luxifit.workoutplan"
        case workoutlog = "luxifit.workoutlog"
        case weekplan = "luxifit.weekplan"
    }
}

struct ExerciseMedia: Decodable, Equatable {
    var gif: String?
    var still: String?
}

struct Catalog: Decodable {
    var foods: [Food]
    var exercises: [Exercise]
    var media: [String: ExerciseMedia]?
}

struct AuthUser: Decodable {
    var id: Int
    var username: String
}

// ---------------- Anatomy ----------------

struct BodyMuscle: Decodable, Identifiable {
    var slug: String
    var paths: [String]
    var id: String { slug }
}

struct BodyView: Decodable {
    var viewBox: String
    var outline: String
    var muscles: [BodyMuscle]
}

struct MuscleInfo: Decodable, Identifiable {
    var name: String
    var what: String
    var train: String
    var id: String { name }
}

struct MuscleGroup: Decodable, Identifiable {
    var id: String
    var name: String
    var icon: String
    var view: String            // "front" | "back"
    var slugs: [String]
    var blurb: String
    var muscles: [MuscleInfo]
}

struct Activation: Decodable {
    var name: String
    var percent: Double
}

struct AnatomyData: Decodable {
    var front: BodyView
    var back: BodyView
    var groups: [MuscleGroup]
    var activation: [String: [Activation]]
}
