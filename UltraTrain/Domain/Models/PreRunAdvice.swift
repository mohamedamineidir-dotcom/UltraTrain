import Foundation

struct PreRunAdvice: Equatable, Sendable {
    let timingDescription: String
    let carbsGrams: Int
    let hydrationMl: Int
    let mealSuggestions: [String]
    let avoidNotes: String?
}
