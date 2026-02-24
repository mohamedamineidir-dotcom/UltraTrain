import Foundation

struct FoodSearchResult: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var brand: String?
    var caloriesPer100g: Int?
    var carbsPer100g: Double?
    var proteinPer100g: Double?
    var fatPer100g: Double?
    var sodiumMgPer100g: Double?
    var servingSizeGrams: Double?
    var imageURL: URL?

    var caloriesPerServing: Int? {
        guard let cal = caloriesPer100g, let serving = servingSizeGrams, serving > 0 else {
            return caloriesPer100g
        }
        return Int(Double(cal) * serving / 100.0)
    }

    var carbsPerServing: Double? {
        guard let val = carbsPer100g, let serving = servingSizeGrams, serving > 0 else {
            return carbsPer100g
        }
        return val * serving / 100.0
    }

    var proteinPerServing: Double? {
        guard let val = proteinPer100g, let serving = servingSizeGrams, serving > 0 else {
            return proteinPer100g
        }
        return val * serving / 100.0
    }

    var fatPerServing: Double? {
        guard let val = fatPer100g, let serving = servingSizeGrams, serving > 0 else {
            return fatPer100g
        }
        return val * serving / 100.0
    }
}
