import Foundation
import SwiftData

@Model
final class NutritionEntrySwiftDataModel {
    var id: UUID = UUID()
    var productId: UUID = UUID()
    var productName: String = ""
    var productTypeRaw: String = "gel"
    var productCaloriesPerServing: Int = 0
    var productCarbsGramsPerServing: Double = 0
    var productSodiumMgPerServing: Int = 0
    var productCaffeinated: Bool = false
    var timingMinutes: Int = 0
    var quantity: Int = 1
    var notes: String?
    var nutritionPlan: NutritionPlanSwiftDataModel?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        productId: UUID = UUID(),
        productName: String = "",
        productTypeRaw: String = "gel",
        productCaloriesPerServing: Int = 0,
        productCarbsGramsPerServing: Double = 0,
        productSodiumMgPerServing: Int = 0,
        productCaffeinated: Bool = false,
        timingMinutes: Int = 0,
        quantity: Int = 1,
        notes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productTypeRaw = productTypeRaw
        self.productCaloriesPerServing = productCaloriesPerServing
        self.productCarbsGramsPerServing = productCarbsGramsPerServing
        self.productSodiumMgPerServing = productSodiumMgPerServing
        self.productCaffeinated = productCaffeinated
        self.timingMinutes = timingMinutes
        self.quantity = quantity
        self.notes = notes
        self.updatedAt = updatedAt
    }
}
