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

    /// Per-format brand preferences. Key is the product type; value is the
    /// set of brand names the athlete explicitly prefers for that format.
    /// Missing key or empty set means "no preference" for that format —
    /// the selector will choose freely from the whole catalog.
    ///
    /// Captured in the nutrition onboarding after the format step, so the
    /// plan generator can stick to the athlete's brand ecosystem (e.g. an
    /// Overstim's user gets Coup de Fouet for caffeine, Gel Long Distance
    /// for sustained fuelling, Hydrixir Long Distance for their bottles).
    var brandPreferences: [ProductType: Set<String>]

    // MARK: - Hydration / sweat

    var sweatProfile: SweatProfile

    // MARK: - Race-day timing

    /// Preferred pre-race meal window. Drives the race-morning phase
    /// of the fuelling protocol. Asked only on HM+ in onboarding;
    /// shorter races default to nil (generator uses 3h).
    var preRaceMealTiming: PreRaceMealTiming?

    /// When the athlete hits flavour fatigue on long efforts. Asked
    /// only on ultras (≥ 60 km). Informs when the aid-station
    /// strategy shifts from gels to real food.
    var ultraPalateTiming: UltraPalateTiming?

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
        brandPreferences: [:],
        sweatProfile: .unknown,
        preRaceMealTiming: nil,
        ultraPalateTiming: nil,
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
        // Decode brandPreferences from a serialised [String: Set<String>] map
        // keyed by ProductType.rawValue. Older payloads without the key fall
        // back to an empty map — the generator treats missing keys as "no
        // preference", so behaviour is unchanged for existing athletes.
        if let raw: [String: Set<String>] = try? c.decodeIfPresent([String: Set<String>].self, forKey: .brandPreferences) {
            var map: [ProductType: Set<String>] = [:]
            for (k, v) in raw {
                if let pt = ProductType(rawValue: k) { map[pt] = v }
            }
            self.brandPreferences = map
        } else {
            self.brandPreferences = [:]
        }
        self.sweatProfile = (try? c.decode(SweatProfile.self, forKey: .sweatProfile)) ?? .unknown
        self.preRaceMealTiming = (try? c.decodeIfPresent(PreRaceMealTiming.self, forKey: .preRaceMealTiming)) ?? nil
        self.ultraPalateTiming = (try? c.decodeIfPresent(UltraPalateTiming.self, forKey: .ultraPalateTiming)) ?? nil
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
        // Serialise brandPreferences as [String: Set<String>] keyed on the
        // raw value so the payload stays readable and portable.
        let brandRaw: [String: Set<String>] = Dictionary(
            uniqueKeysWithValues: brandPreferences.map { ($0.key.rawValue, $0.value) }
        )
        try c.encodeIfPresent(brandRaw.isEmpty ? nil : brandRaw, forKey: .brandPreferences)
        try c.encode(sweatProfile, forKey: .sweatProfile)
        try c.encodeIfPresent(preRaceMealTiming, forKey: .preRaceMealTiming)
        try c.encodeIfPresent(ultraPalateTiming, forKey: .ultraPalateTiming)
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
        brandPreferences: [ProductType: Set<String>] = [:],
        sweatProfile: SweatProfile = .unknown,
        preRaceMealTiming: PreRaceMealTiming? = nil,
        ultraPalateTiming: UltraPalateTiming? = nil,
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
        self.brandPreferences = brandPreferences
        self.sweatProfile = sweatProfile
        self.preRaceMealTiming = preRaceMealTiming
        self.ultraPalateTiming = ultraPalateTiming
        self.onboardingCompleted = onboardingCompleted
    }

    private enum CodingKeys: String, CodingKey {
        case avoidCaffeine, preferRealFood, excludedProductIds, favoriteProductIds
        case nutritionGoal, carbsPerHourTolerance
        case caffeineSensitivity, caffeineHabitMgPerDay
        case giSensitivities, dietaryRestrictions, preferredFormats
        case brandPreferences
        case sweatProfile
        case preRaceMealTiming, ultraPalateTiming
        case onboardingCompleted
    }
}
