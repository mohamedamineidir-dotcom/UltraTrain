import Foundation
import SwiftData

@Model
final class NutritionProductSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var caloriesPerServing: Int
    var carbsGramsPerServing: Double
    var sodiumMgPerServing: Int
    var caffeinated: Bool

    init(
        id: UUID,
        name: String,
        typeRaw: String,
        caloriesPerServing: Int,
        carbsGramsPerServing: Double,
        sodiumMgPerServing: Int,
        caffeinated: Bool
    ) {
        self.id = id
        self.name = name
        self.typeRaw = typeRaw
        self.caloriesPerServing = caloriesPerServing
        self.carbsGramsPerServing = carbsGramsPerServing
        self.sodiumMgPerServing = sodiumMgPerServing
        self.caffeinated = caffeinated
    }
}
