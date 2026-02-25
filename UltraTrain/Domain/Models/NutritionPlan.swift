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
