import Foundation
import SwiftData

@Model
final class NutritionPlanSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var raceId: UUID
    var caloriesPerHour: Int
    var hydrationMlPerHour: Int
    var sodiumMgPerHour: Int
    @Relationship(deleteRule: .cascade) var entries: [NutritionEntrySwiftDataModel]
    var gutTrainingSessionIds: [UUID]

    init(
        id: UUID,
        raceId: UUID,
        caloriesPerHour: Int,
        hydrationMlPerHour: Int,
        sodiumMgPerHour: Int,
        entries: [NutritionEntrySwiftDataModel],
        gutTrainingSessionIds: [UUID]
    ) {
        self.id = id
        self.raceId = raceId
        self.caloriesPerHour = caloriesPerHour
        self.hydrationMlPerHour = hydrationMlPerHour
        self.sodiumMgPerHour = sodiumMgPerHour
        self.entries = entries
        self.gutTrainingSessionIds = gutTrainingSessionIds
    }
}
