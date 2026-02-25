import Foundation

struct DuringRunAdvice: Equatable, Sendable {
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let carbsGramsPerHour: Int
    let suggestedProducts: [ProductSuggestion]
    let notes: String?
}
