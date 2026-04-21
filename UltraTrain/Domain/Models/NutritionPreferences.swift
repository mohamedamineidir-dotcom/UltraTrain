import Foundation

/// Athlete preferences that personalize the race-day nutrition plan.
///
/// Populated by the pre-plan nutrition onboarding sheet (Phase 3) and
/// refined over time by the gut-training feedback loop (Phase 4). All new
/// fields default to safe sensible values so a plan can be generated even
/// when the athlete skips the onboarding.
struct NutritionPreferences: Equatable, Sendable, Codable {

    // MARK: - Legacy fields (kept for backwards compat)

    var avoidCaffeine: Bool
    var preferRealFood: Bool
    var excludedProductIds: Set<UUID>
    var favoriteProductIds: [UUID]

    // MARK: - Goal & tolerance

    var nutritionGoal: NutritionGoal
    /// Observed carbs-per-hour tolerance from gut-training runs. When set,
    /// the generator will not prescribe above this ceiling.
    var carbsPerHourTolerance: Int?
    var caffeineSensitivity: CaffeineSensitivity
    /// Self-reported daily caffeine intake (mg) — coffee ~95 mg, espresso ~63 mg.
    var caffeineHabitMgPerDay: Int?

    // MARK: - GI & dietary filters

    var giSensitivities: Set<GISensitivity>
    var dietaryRestrictions: Set<DietaryRestriction>

    // MARK: - Format preferences

    /// Product types the athlete prefers. Empty set = no preference (use all).
    var preferredFormats: Set<ProductType>

    // MARK: - Hydration / sweat

    var sweatProfile: SweatProfile

    // MARK: - Onboarding state

    /// True when the athlete has completed the pre-plan nutrition onboarding.
    /// When false and the plan is generated, the generator uses safe defaults
    /// and the UI surfaces a "personalize your plan" prompt.
    var onboardingCompleted: Bool

    // MARK: - Default

    static let `default` = NutritionPreferences(
        avoidCaffeine: false,
        preferRealFood: false,
        excludedProductIds: [],
        favoriteProductIds: [],
        nutritionGoal: .targetTime,
        carbsPerHourTolerance: nil,
        caffeineSensitivity: .moderate,
        caffeineHabitMgPerDay: nil,
        giSensitivities: [],
        dietaryRestrictions: [],
        preferredFormats: [],
        sweatProfile: .unknown,
        onboardingCompleted: false
    )

    // MARK: - Backwards-compatible Codable

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.avoidCaffeine = (try? c.decode(Bool.self, forKey: .avoidCaffeine)) ?? false
        self.preferRealFood = (try? c.decode(Bool.self, forKey: .preferRealFood)) ?? false
        let excluded: Set<UUID>? = try? c.decode(Set<UUID>.self, forKey: .excludedProductIds)
        self.excludedProductIds = excluded ?? Set<UUID>()
        let favorites: [UUID]? = try? c.decode([UUID].self, forKey: .favoriteProductIds)
        self.favoriteProductIds = favorites ?? [UUID]()
        self.nutritionGoal = (try? c.decode(NutritionGoal.self, forKey: .nutritionGoal)) ?? .targetTime
        self.carbsPerHourTolerance = (try? c.decodeIfPresent(Int.self, forKey: .carbsPerHourTolerance)) ?? nil
        self.caffeineSensitivity = (try? c.decode(CaffeineSensitivity.self, forKey: .caffeineSensitivity)) ?? .moderate
        self.caffeineHabitMgPerDay = (try? c.decodeIfPresent(Int.self, forKey: .caffeineHabitMgPerDay)) ?? nil
        let gi: Set<GISensitivity>? = try? c.decode(Set<GISensitivity>.self, forKey: .giSensitivities)
        self.giSensitivities = gi ?? Set<GISensitivity>()
        let diet: Set<DietaryRestriction>? = try? c.decode(Set<DietaryRestriction>.self, forKey: .dietaryRestrictions)
        self.dietaryRestrictions = diet ?? Set<DietaryRestriction>()
        let formats: Set<ProductType>? = try? c.decode(Set<ProductType>.self, forKey: .preferredFormats)
        self.preferredFormats = formats ?? Set<ProductType>()
        self.sweatProfile = (try? c.decode(SweatProfile.self, forKey: .sweatProfile)) ?? .unknown
        self.onboardingCompleted = (try? c.decode(Bool.self, forKey: .onboardingCompleted)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(avoidCaffeine, forKey: .avoidCaffeine)
        try c.encode(preferRealFood, forKey: .preferRealFood)
        try c.encode(excludedProductIds, forKey: .excludedProductIds)
        try c.encode(favoriteProductIds, forKey: .favoriteProductIds)
        try c.encode(nutritionGoal, forKey: .nutritionGoal)
        try c.encodeIfPresent(carbsPerHourTolerance, forKey: .carbsPerHourTolerance)
        try c.encode(caffeineSensitivity, forKey: .caffeineSensitivity)
        try c.encodeIfPresent(caffeineHabitMgPerDay, forKey: .caffeineHabitMgPerDay)
        try c.encode(giSensitivities, forKey: .giSensitivities)
        try c.encode(dietaryRestrictions, forKey: .dietaryRestrictions)
        try c.encode(preferredFormats, forKey: .preferredFormats)
        try c.encode(sweatProfile, forKey: .sweatProfile)
        try c.encode(onboardingCompleted, forKey: .onboardingCompleted)
    }

    init(
        avoidCaffeine: Bool,
        preferRealFood: Bool,
        excludedProductIds: Set<UUID>,
        favoriteProductIds: [UUID] = [],
        nutritionGoal: NutritionGoal = .targetTime,
        carbsPerHourTolerance: Int? = nil,
        caffeineSensitivity: CaffeineSensitivity = .moderate,
        caffeineHabitMgPerDay: Int? = nil,
        giSensitivities: Set<GISensitivity> = [],
        dietaryRestrictions: Set<DietaryRestriction> = [],
        preferredFormats: Set<ProductType> = [],
        sweatProfile: SweatProfile = .unknown,
        onboardingCompleted: Bool = false
    ) {
        self.avoidCaffeine = avoidCaffeine
        self.preferRealFood = preferRealFood
        self.excludedProductIds = excludedProductIds
        self.favoriteProductIds = favoriteProductIds
        self.nutritionGoal = nutritionGoal
        self.carbsPerHourTolerance = carbsPerHourTolerance
        self.caffeineSensitivity = caffeineSensitivity
        self.caffeineHabitMgPerDay = caffeineHabitMgPerDay
        self.giSensitivities = giSensitivities
        self.dietaryRestrictions = dietaryRestrictions
        self.preferredFormats = preferredFormats
        self.sweatProfile = sweatProfile
        self.onboardingCompleted = onboardingCompleted
    }

    private enum CodingKeys: String, CodingKey {
        case avoidCaffeine, preferRealFood, excludedProductIds, favoriteProductIds
        case nutritionGoal, carbsPerHourTolerance
        case caffeineSensitivity, caffeineHabitMgPerDay
        case giSensitivities, dietaryRestrictions, preferredFormats
        case sweatProfile, onboardingCompleted
    }
}
