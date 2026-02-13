import Foundation

struct NutritionPlan: Identifiable, Equatable, Sendable {
    let id: UUID
    var raceId: UUID
    var caloriesPerHour: Int
    var hydrationMlPerHour: Int
    var sodiumMgPerHour: Int
    var entries: [NutritionEntry]
    var gutTrainingSessionIds: [UUID]
}

struct NutritionEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var product: NutritionProduct
    var timingMinutes: Int
    var quantity: Int
    var notes: String?
}

struct NutritionProduct: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var type: ProductType
    var caloriesPerServing: Int
    var carbsGramsPerServing: Double
    var sodiumMgPerServing: Int
    var caffeinated: Bool
}

enum ProductType: String, CaseIterable, Sendable {
    case gel
    case bar
    case drink
    case chew
    case realFood
    case salt
}
