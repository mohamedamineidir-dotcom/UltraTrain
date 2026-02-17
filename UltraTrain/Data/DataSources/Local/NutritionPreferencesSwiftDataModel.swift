import Foundation
import SwiftData

@Model
final class NutritionPreferencesSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var avoidCaffeine: Bool
    var preferRealFood: Bool
    var excludedProductIdsData: Data

    init(
        id: UUID,
        avoidCaffeine: Bool,
        preferRealFood: Bool,
        excludedProductIdsData: Data
    ) {
        self.id = id
        self.avoidCaffeine = avoidCaffeine
        self.preferRealFood = preferRealFood
        self.excludedProductIdsData = excludedProductIdsData
    }
}
