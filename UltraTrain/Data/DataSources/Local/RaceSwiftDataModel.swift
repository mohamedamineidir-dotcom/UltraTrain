import Foundation
import SwiftData

@Model
final class RaceSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var priorityRaw: String
    var goalTypeRaw: String
    var goalValue: Double?
    var terrainDifficultyRaw: String
    @Relationship(deleteRule: .cascade) var checkpointModels: [CheckpointSwiftDataModel]

    init(
        id: UUID,
        name: String,
        date: Date,
        distanceKm: Double,
        elevationGainM: Double,
        elevationLossM: Double,
        priorityRaw: String,
        goalTypeRaw: String,
        goalValue: Double?,
        terrainDifficultyRaw: String,
        checkpointModels: [CheckpointSwiftDataModel] = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.priorityRaw = priorityRaw
        self.goalTypeRaw = goalTypeRaw
        self.goalValue = goalValue
        self.terrainDifficultyRaw = terrainDifficultyRaw
        self.checkpointModels = checkpointModels
    }
}
