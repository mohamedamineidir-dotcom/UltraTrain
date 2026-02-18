import Foundation
import SwiftData

@Model
final class NutritionPreferencesSwiftDataModel {
    var id: UUID = UUID()
    var avoidCaffeine: Bool = false
    var preferRealFood: Bool = false
    var excludedProductIdsData: Data = Data()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        avoidCaffeine: Bool = false,
        preferRealFood: Bool = false,
        excludedProductIdsData: Data = Data(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.avoidCaffeine = avoidCaffeine
        self.preferRealFood = preferRealFood
        self.excludedProductIdsData = excludedProductIdsData
        self.updatedAt = updatedAt
    }
}
