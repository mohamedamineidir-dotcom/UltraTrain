import Foundation

enum NutritionPreferencesMapper {

    static func toDomain(_ model: NutritionPreferencesSwiftDataModel) -> NutritionPreferences {
        let excludedIds = decodeUUIDSet(from: model.excludedProductIdsData)
        let favoriteIds = decodeUUIDArray(from: model.favoriteProductIdsData)
        return NutritionPreferences(
            avoidCaffeine: model.avoidCaffeine,
            preferRealFood: model.preferRealFood,
            excludedProductIds: excludedIds,
            favoriteProductIds: favoriteIds
        )
    }

    static func toSwiftData(_ preferences: NutritionPreferences) -> NutritionPreferencesSwiftDataModel {
        NutritionPreferencesSwiftDataModel(
            id: UUID(),
            avoidCaffeine: preferences.avoidCaffeine,
            preferRealFood: preferences.preferRealFood,
            excludedProductIdsData: encodeUUIDSet(preferences.excludedProductIds),
            favoriteProductIdsData: encodeUUIDArray(preferences.favoriteProductIds)
        )
    }

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
