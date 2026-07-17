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

    init(id: String, name: String, icon: String, category: String, servingLabel: String,
         perServing: Macros, vitamins: String?, isJunk: Bool, isDefault: Bool) {
        self.id = id; self.name = name; self.icon = icon; self.category = category
        self.servingLabel = servingLabel; self.perServing = perServing
        self.vitamins = vitamins; self.isJunk = isJunk; self.isDefault = isDefault
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "🍽️"
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "other"
        servingLabel = try c.decodeIfPresent(String.self, forKey: .servingLabel) ?? "1 serving"
        perServing = try c.decodeIfPresent(Macros.self, forKey: .perServing) ?? .zero
        vitamins = try c.decodeIfPresent(String.self, forKey: .vitamins)
        isJunk = try c.decodeIfPresent(Bool.self, forKey: .isJunk) ?? false
        isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, category, servingLabel, perServing, vitamins, isJunk, isDefault
    }
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

    init(id: String, name: String, icon: String, category: String, equipment: String,
         primary: String, weighted: Bool, isDefault: Bool) {
        self.id = id; self.name = name; self.icon = icon; self.category = category
        self.equipment = equipment; self.primary = primary
        self.weighted = weighted; self.isDefault = isDefault
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "🏋️"
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "other"
        equipment = try c.decodeIfPresent(String.self, forKey: .equipment) ?? "Other"
        primary = try c.decodeIfPresent(String.self, forKey: .primary) ?? ""
        weighted = try c.decodeIfPresent(Bool.self, forKey: .weighted) ?? true
        isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, category, equipment, primary, weighted, isDefault
    }
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

    init(rest: Bool, items: [PlanExercise]) {
        self.rest = rest
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rest = try c.decodeIfPresent(Bool.self, forKey: .rest) ?? false
        items = try c.decodeIfPresent([PlanExercise].self, forKey: .items) ?? []
    }

    private enum CodingKeys: String, CodingKey { case rest, items }
}

/// What was actually trained on a date — carries working weight for overload.
struct LoggedExercise: Codable, Equatable {
    var exerciseId: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var done: Bool

    /// Lenient decode — older payloads may omit `done` / `weightKg`.
    init(exerciseId: String, sets: Int, reps: Int, weightKg: Double, done: Bool) {
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.done = done
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try c.decode(String.self, forKey: .exerciseId)
        sets = try c.decodeIfPresent(Int.self, forKey: .sets) ?? WorkoutDefaults.sets
        reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? WorkoutDefaults.reps
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg) ?? 0
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case exerciseId, sets, reps, weightKg, done
    }
}

struct WorkoutDayLog: Codable, Equatable {
    var date: String
    var rest: Bool
    var items: [LoggedExercise]

    init(date: String, rest: Bool, items: [LoggedExercise]) {
        self.date = date
        self.rest = rest
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        rest = try c.decodeIfPresent(Bool.self, forKey: .rest) ?? false
        items = try c.decodeIfPresent([LoggedExercise].self, forKey: .items) ?? []
    }

    private enum CodingKeys: String, CodingKey { case date, rest, items }
}

/// Weekly routines are Record<weekday(0-6), …> → JSON object with string keys.
typealias WorkoutWeekPlan = [String: WorkoutDayPlan]
typealias MealMap = [String: [PlanItem]]
typealias WeekPlan = [String: MealMap]

enum WorkoutDefaults {
    static let sets = 3
    static let reps = 10
    static let weightStep = 0.5
    /// Body-weight log step — 0.25 kg (250 g) per tap.
    static let bodyWeightStep = 0.25
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
    var progressPhotos: [ProgressPhoto]?

    enum CodingKeys: String, CodingKey {
        case profile = "luxifit.profile"
        case log = "luxifit.log"
        case weightlog = "luxifit.weightlog"
        case foods = "luxifit.foods"
        case exercises = "luxifit.exercises"
        case workoutplan = "luxifit.workoutplan"
        case workoutlog = "luxifit.workoutlog"
        case weekplan = "luxifit.weekplan"
        case progressPhotos = "luxifit.progressphotos"
    }
}

// ---------------- Progress photos (bytes in Cloudflare R2; metadata in app_state) ----------------

/// Daily progress photo. New uploads store JPEG bytes in R2 (`key`) and only
/// metadata in Supabase. Legacy rows may still have `jpegBase64` until re-saved.
struct ProgressPhoto: Codable, Identifiable, Equatable {
    var id: String
    var date: String            // yyyy-MM-dd
    /// Legacy: compressed JPEG base64, no data: prefix. Empty when using R2.
    var jpegBase64: String
    /// Cloudflare R2 object key, e.g. `progress/{userId}/{id}.jpg`
    var key: String?
    /// Relative API path for authenticated fetch, e.g. `/api/media?key=...`
    var url: String?
    var note: String?
    var createdAt: Double       // unix seconds

    init(id: String = UUID().uuidString.lowercased(),
         date: String,
         jpegBase64: String = "",
         key: String? = nil,
         url: String? = nil,
         note: String? = nil,
         createdAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.date = date
        self.jpegBase64 = jpegBase64
        self.key = key
        self.url = url
        self.note = note
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, date, jpegBase64, key, url, note, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        jpegBase64 = try c.decodeIfPresent(String.self, forKey: .jpegBase64) ?? ""
        key = try c.decodeIfPresent(String.self, forKey: .key)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        if let d = try c.decodeIfPresent(Double.self, forKey: .createdAt) {
            createdAt = d
        } else if let i = try c.decodeIfPresent(Int.self, forKey: .createdAt) {
            createdAt = Double(i)
        } else {
            createdAt = Date().timeIntervalSince1970
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        // Prefer not to re-sync giant base64 once R2 holds the file.
        if !jpegBase64.isEmpty && (key == nil || key?.isEmpty == true) {
            try c.encode(jpegBase64, forKey: .jpegBase64)
        } else {
            try c.encode("", forKey: .jpegBase64)
        }
        try c.encodeIfPresent(key, forKey: .key)
        try c.encodeIfPresent(url, forKey: .url)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encode(createdAt, forKey: .createdAt)
    }

    /// True when we can load from R2 (or have a media API path).
    var hasRemoteMedia: Bool {
        if let k = key, !k.isEmpty { return true }
        if let u = url, !u.isEmpty { return true }
        return false
    }

    var hasLocalBase64: Bool { !jpegBase64.isEmpty }
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

// ---------------- Voice logging (unified food + workout) ----------------

struct FoodLite: Encodable {
    let id: String
    let name: String
    let serving: String
}

struct ExerciseLite: Encodable {
    let id: String
    let name: String
    let primary: String
}

struct VoiceParseRequest: Encodable {
    let transcript: String
    let foods: [FoodLite]
    let exercises: [ExerciseLite]
    let plannedFoodIds: [String]
    let plannedExerciseIds: [String]
    let unified: Bool
}

struct ParsedItem: Decodable, Identifiable {
    let spoken: String
    let foodId: String?
    let foodName: String
    let quantity: Double
    var id: String { spoken + "|" + foodName }
}

struct ParsedWorkoutItem: Decodable, Identifiable {
    let spoken: String
    let exerciseId: String?
    let exerciseName: String
    let sets: Double?
    let reps: Double?
    let weightKg: Double?
    var id: String { spoken + "|" + exerciseName + "|\(sets ?? 0)|\(reps ?? 0)" }
}

struct ParsedFoodLog: Decodable {
    let meal: String?
    let items: [ParsedItem]
}

/// Unified voice response — food, workout, or both.
struct UnifiedVoiceParse: Decodable {
    let kind: String?
    let meal: String?
    let foodItems: [ParsedItem]?
    let workoutItems: [ParsedWorkoutItem]?
    /// Back-compat with older food-only field.
    let items: [ParsedItem]?

    var foods: [ParsedItem] { foodItems ?? items ?? [] }
    var workouts: [ParsedWorkoutItem] { workoutItems ?? [] }
}
