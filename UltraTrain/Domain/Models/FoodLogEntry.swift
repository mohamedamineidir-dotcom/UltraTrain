import Foundation

struct FoodLogEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var mealType: MealType
    var description: String
    var caloriesEstimate: Int?
    var carbsGrams: Double?
    var proteinGrams: Double?
    var fatGrams: Double?
    var hydrationMl: Int?
    var productId: UUID?
}
