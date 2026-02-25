import Foundation

struct PostRunAdvice: Equatable, Sendable {
    let priority: RecoveryPriority
    let windowDescription: String
    let proteinGrams: Int
    let carbsGrams: Int
    let hydrationMl: Int
    let mealSuggestions: [String]
}
