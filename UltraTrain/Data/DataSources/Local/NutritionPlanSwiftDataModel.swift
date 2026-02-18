import Foundation
import SwiftData

@Model
final class NutritionPlanSwiftDataModel {
    var id: UUID = UUID()
    var raceId: UUID = UUID()
    var caloriesPerHour: Int = 0
    var hydrationMlPerHour: Int = 0
    var sodiumMgPerHour: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \NutritionEntrySwiftDataModel.nutritionPlan)
    var entries: [NutritionEntrySwiftDataModel] = []
    var gutTrainingSessionIds: [UUID] = []
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        caloriesPerHour: Int = 0,
        hydrationMlPerHour: Int = 0,
        sodiumMgPerHour: Int = 0,
        entries: [NutritionEntrySwiftDataModel] = [],
        gutTrainingSessionIds: [UUID] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.raceId = raceId
        self.caloriesPerHour = caloriesPerHour
        self.hydrationMlPerHour = hydrationMlPerHour
        self.sodiumMgPerHour = sodiumMgPerHour
        self.entries = entries
        self.gutTrainingSessionIds = gutTrainingSessionIds
        self.updatedAt = updatedAt
    }
}
