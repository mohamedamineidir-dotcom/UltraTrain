import Foundation

struct NutritionPreferences: Equatable, Sendable {
    var avoidCaffeine: Bool
    var preferRealFood: Bool
    var excludedProductIds: Set<UUID>

    static let `default` = NutritionPreferences(
        avoidCaffeine: false,
        preferRealFood: false,
        excludedProductIds: []
    )
}
