import Foundation
import SwiftData

@Model
final class NutritionPreferencesSwiftDataModel {
    var id: UUID = UUID()
    // Legacy columns (kept for backwards compat with existing local DBs)
    var avoidCaffeine: Bool = false
    var preferRealFood: Bool = false
    var excludedProductIdsData: Data = Data()
    var favoriteProductIdsData: Data = Data()
    var updatedAt: Date = Date()
    // New columns — all optional so existing stores migrate cleanly.
    // Richer nested fields (sets, SweatProfile) are JSON-encoded into
    // `extendedPreferencesJson` to avoid a wave of new columns.
    var nutritionGoalRaw: String?
    var onboardingCompleted: Bool = false
    var extendedPreferencesJson: Data?

    init(
        id: UUID = UUID(),
        avoidCaffeine: Bool = false,
        preferRealFood: Bool = false,
        excludedProductIdsData: Data = Data(),
        favoriteProductIdsData: Data = Data(),
        updatedAt: Date = Date(),
        nutritionGoalRaw: String? = nil,
        onboardingCompleted: Bool = false,
        extendedPreferencesJson: Data? = nil
    ) {
        self.id = id
        self.avoidCaffeine = avoidCaffeine
        self.preferRealFood = preferRealFood
        self.excludedProductIdsData = excludedProductIdsData
        self.favoriteProductIdsData = favoriteProductIdsData
        self.updatedAt = updatedAt
        self.nutritionGoalRaw = nutritionGoalRaw
        self.onboardingCompleted = onboardingCompleted
        self.extendedPreferencesJson = extendedPreferencesJson
    }
}
