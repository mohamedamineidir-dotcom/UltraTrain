import Foundation
import SwiftData

@Model
final class TrainingPlanSwiftDataModel {
    var id: UUID = UUID()
    var athleteId: UUID = UUID()
    var targetRaceId: UUID = UUID()
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \TrainingWeekSwiftDataModel.plan)
    var weeks: [TrainingWeekSwiftDataModel] = []
    var intermediateRaceIds: [UUID] = []
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        targetRaceId: UUID = UUID(),
        createdAt: Date = Date(),
        weeks: [TrainingWeekSwiftDataModel] = [],
        intermediateRaceIds: [UUID] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.athleteId = athleteId
        self.targetRaceId = targetRaceId
        self.createdAt = createdAt
        self.weeks = weeks
        self.intermediateRaceIds = intermediateRaceIds
        self.updatedAt = updatedAt
    }
}
