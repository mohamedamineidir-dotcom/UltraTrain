import Foundation
import SwiftData

@Model
final class TrainingPlanSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var athleteId: UUID
    var targetRaceId: UUID
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var weeks: [TrainingWeekSwiftDataModel]
    var intermediateRaceIds: [UUID]

    init(
        id: UUID,
        athleteId: UUID,
        targetRaceId: UUID,
        createdAt: Date,
        weeks: [TrainingWeekSwiftDataModel],
        intermediateRaceIds: [UUID]
    ) {
        self.id = id
        self.athleteId = athleteId
        self.targetRaceId = targetRaceId
        self.createdAt = createdAt
        self.weeks = weeks
        self.intermediateRaceIds = intermediateRaceIds
    }
}
