import Foundation
import SwiftData

@Model
final class FoodLogEntrySwiftDataModel {
    var id: UUID = UUID()
    var date: Date = Date.distantPast
    var mealTypeRaw: String = "breakfast"
    var entryDescription: String = ""
    var caloriesEstimate: Int?
    var carbsGrams: Double?
    var proteinGrams: Double?
    var fatGrams: Double?
    var hydrationMl: Int?
    var productId: UUID?

    init(
        id: UUID = UUID(),
        date: Date = Date.distantPast,
        mealTypeRaw: String = "breakfast",
        entryDescription: String = "",
        caloriesEstimate: Int? = nil,
        carbsGrams: Double? = nil,
        proteinGrams: Double? = nil,
        fatGrams: Double? = nil,
        hydrationMl: Int? = nil,
        productId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.mealTypeRaw = mealTypeRaw
        self.entryDescription = entryDescription
        self.caloriesEstimate = caloriesEstimate
        self.carbsGrams = carbsGrams
        self.proteinGrams = proteinGrams
        self.fatGrams = fatGrams
        self.hydrationMl = hydrationMl
        self.productId = productId
    }
}
