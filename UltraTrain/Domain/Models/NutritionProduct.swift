import Foundation

struct NutritionProduct: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var type: ProductType
    var caloriesPerServing: Int
    var carbsGramsPerServing: Double
    var sodiumMgPerServing: Int
    var caffeinated: Bool
}
