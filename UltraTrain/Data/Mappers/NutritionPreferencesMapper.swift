import Foundation

enum NutritionPreferencesMapper {

    // MARK: - Extended bundle (everything beyond the legacy columns)

    private struct Extended: Codable {
        var caffeineSensitivity: CaffeineSensitivity
        var caffeineHabitMgPerDay: Int?
        var carbsPerHourTolerance: Int?
        var giSensitivities: Set<GISensitivity>
        var dietaryRestrictions: Set<DietaryRestriction>
        var preferredFormats: Set<ProductType>
        var sweatProfile: SweatProfile
    }

    // MARK: - To Domain

    static func toDomain(_ model: NutritionPreferencesSwiftDataModel) -> NutritionPreferences {
        let excludedIds = decodeUUIDSet(from: model.excludedProductIdsData)
        let favoriteIds = decodeUUIDArray(from: model.favoriteProductIdsData)
        let goal = model.nutritionGoalRaw.flatMap(NutritionGoal.init(rawValue:)) ?? .targetTime
        let extended = decodeExtended(from: model.extendedPreferencesJson)

        return NutritionPreferences(
            avoidCaffeine: model.avoidCaffeine,
            preferRealFood: model.preferRealFood,
            excludedProductIds: excludedIds,
            favoriteProductIds: favoriteIds,
            nutritionGoal: goal,
            carbsPerHourTolerance: extended.carbsPerHourTolerance,
            caffeineSensitivity: extended.caffeineSensitivity,
            caffeineHabitMgPerDay: extended.caffeineHabitMgPerDay,
            giSensitivities: extended.giSensitivities,
            dietaryRestrictions: extended.dietaryRestrictions,
            preferredFormats: extended.preferredFormats,
            sweatProfile: extended.sweatProfile,
            onboardingCompleted: model.onboardingCompleted
        )
    }

    // MARK: - To SwiftData

    static func toSwiftData(_ preferences: NutritionPreferences) -> NutritionPreferencesSwiftDataModel {
        let extended = Extended(
            caffeineSensitivity: preferences.caffeineSensitivity,
            caffeineHabitMgPerDay: preferences.caffeineHabitMgPerDay,
            carbsPerHourTolerance: preferences.carbsPerHourTolerance,
            giSensitivities: preferences.giSensitivities,
            dietaryRestrictions: preferences.dietaryRestrictions,
            preferredFormats: preferences.preferredFormats,
            sweatProfile: preferences.sweatProfile
        )
        return NutritionPreferencesSwiftDataModel(
            id: UUID(),
            avoidCaffeine: preferences.avoidCaffeine,
            preferRealFood: preferences.preferRealFood,
            excludedProductIdsData: encodeUUIDSet(preferences.excludedProductIds),
            favoriteProductIdsData: encodeUUIDArray(preferences.favoriteProductIds),
            nutritionGoalRaw: preferences.nutritionGoal.rawValue,
            onboardingCompleted: preferences.onboardingCompleted,
            extendedPreferencesJson: (try? JSONEncoder().encode(extended))
        )
    }

    // MARK: - Extended encoding

    private static func decodeExtended(from data: Data?) -> Extended {
        let fallback = Extended(
            caffeineSensitivity: .moderate,
            caffeineHabitMgPerDay: nil,
            carbsPerHourTolerance: nil,
            giSensitivities: [],
            dietaryRestrictions: [],
            preferredFormats: [],
            sweatProfile: .unknown
        )
        guard let data, !data.isEmpty else { return fallback }
        return (try? JSONDecoder().decode(Extended.self, from: data)) ?? fallback
    }

    // MARK: - UUID JSON helpers (unchanged)

    private static func encodeUUIDSet(_ ids: Set<UUID>) -> Data {
        let strings = ids.map(\.uuidString)
        return (try? JSONEncoder().encode(strings)) ?? Data()
    }

    private static func decodeUUIDSet(from data: Data) -> Set<UUID> {
        guard let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }

    private static func encodeUUIDArray(_ ids: [UUID]) -> Data {
        let strings = ids.map(\.uuidString)
        return (try? JSONEncoder().encode(strings)) ?? Data()
    }

    private static func decodeUUIDArray(from data: Data) -> [UUID] {
        guard let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }
}
