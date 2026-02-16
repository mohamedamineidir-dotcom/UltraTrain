import Foundation

struct SessionNutritionAdvice: Equatable, Sendable {
    let preRun: PreRunAdvice?
    let duringRun: DuringRunAdvice?
    let postRun: PostRunAdvice
    let isGutTrainingRecommended: Bool
}

struct PreRunAdvice: Equatable, Sendable {
    let timingDescription: String
    let carbsGrams: Int
    let hydrationMl: Int
    let mealSuggestions: [String]
    let avoidNotes: String?
}

struct DuringRunAdvice: Equatable, Sendable {
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let carbsGramsPerHour: Int
    let suggestedProducts: [ProductSuggestion]
    let notes: String?
}

struct ProductSuggestion: Equatable, Sendable {
    let product: NutritionProduct
    let frequencyDescription: String
}

struct PostRunAdvice: Equatable, Sendable {
    let priority: RecoveryPriority
    let windowDescription: String
    let proteinGrams: Int
    let carbsGrams: Int
    let hydrationMl: Int
    let mealSuggestions: [String]
}

enum RecoveryPriority: String, Equatable, Sendable {
    case low
    case moderate
    case high
}
