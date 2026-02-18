import Foundation
import SwiftData

@Model
final class NutritionProductSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = "gel"
    var caloriesPerServing: Int = 0
    var carbsGramsPerServing: Double = 0
    var sodiumMgPerServing: Int = 0
    var caffeinated: Bool = false
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        typeRaw: String = "gel",
        caloriesPerServing: Int = 0,
        carbsGramsPerServing: Double = 0,
        sodiumMgPerServing: Int = 0,
        caffeinated: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.typeRaw = typeRaw
        self.caloriesPerServing = caloriesPerServing
        self.carbsGramsPerServing = carbsGramsPerServing
        self.sodiumMgPerServing = sodiumMgPerServing
        self.caffeinated = caffeinated
        self.updatedAt = updatedAt
    }
}
