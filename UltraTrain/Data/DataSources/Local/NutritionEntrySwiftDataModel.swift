import Foundation
import SwiftData

@Model
final class NutritionEntrySwiftDataModel {
    @Attribute(.unique) var id: UUID
    var productId: UUID
    var productName: String
    var productTypeRaw: String
    var productCaloriesPerServing: Int
    var productCarbsGramsPerServing: Double
    var productSodiumMgPerServing: Int
    var productCaffeinated: Bool
    var timingMinutes: Int
    var quantity: Int
    var notes: String?

    init(
        id: UUID,
        productId: UUID,
        productName: String,
        productTypeRaw: String,
        productCaloriesPerServing: Int,
        productCarbsGramsPerServing: Double,
        productSodiumMgPerServing: Int,
        productCaffeinated: Bool,
        timingMinutes: Int,
        quantity: Int,
        notes: String?
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
    }
}
