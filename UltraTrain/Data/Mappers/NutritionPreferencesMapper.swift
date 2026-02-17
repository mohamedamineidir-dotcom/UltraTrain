import Foundation

enum NutritionPreferencesMapper {

    static func toDomain(_ model: NutritionPreferencesSwiftDataModel) -> NutritionPreferences {
        let excludedIds = decodeUUIDs(from: model.excludedProductIdsData)
        return NutritionPreferences(
            avoidCaffeine: model.avoidCaffeine,
            preferRealFood: model.preferRealFood,
            excludedProductIds: excludedIds
        )
    }

    static func toSwiftData(_ preferences: NutritionPreferences) -> NutritionPreferencesSwiftDataModel {
        NutritionPreferencesSwiftDataModel(
            id: UUID(),
            avoidCaffeine: preferences.avoidCaffeine,
            preferRealFood: preferences.preferRealFood,
            excludedProductIdsData: encodeUUIDs(preferences.excludedProductIds)
        )
    }

    private static func encodeUUIDs(_ ids: Set<UUID>) -> Data {
        let strings = ids.map(\.uuidString)
        return (try? JSONEncoder().encode(strings)) ?? Data()
    }

    private static func decodeUUIDs(from data: Data) -> Set<UUID> {
        guard let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
