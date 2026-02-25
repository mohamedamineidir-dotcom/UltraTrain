import Foundation

struct NutritionEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var product: NutritionProduct
    var timingMinutes: Int
    var quantity: Int
    var notes: String?
}
