import Foundation
import SwiftData

@Model
final class RaceSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var priorityRaw: String = "A"
    var goalTypeRaw: String = "finish"
    var goalValue: Double?
    var terrainDifficultyRaw: String = "moderate"
    @Relationship(deleteRule: .cascade, inverse: \CheckpointSwiftDataModel.race)
    var checkpointModels: [CheckpointSwiftDataModel] = []
    var actualFinishTime: Double?
    var linkedRunId: UUID?
    var locationLatitude: Double?
    var locationLongitude: Double?
    @Attribute(.externalStorage) var forecastedWeatherData: Data?
    @Attribute(.externalStorage) var courseRouteData: Data?
    var savedRouteId: UUID?
    var updatedAt: Date = Date()
    var serverUpdatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String = "",
        date: Date = Date(),
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        elevationLossM: Double = 0,
        priorityRaw: String = "A",
        goalTypeRaw: String = "finish",
        goalValue: Double? = nil,
        terrainDifficultyRaw: String = "moderate",
        checkpointModels: [CheckpointSwiftDataModel] = [],
        actualFinishTime: Double? = nil,
        linkedRunId: UUID? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        forecastedWeatherData: Data? = nil,
        courseRouteData: Data? = nil,
        savedRouteId: UUID? = nil,
        updatedAt: Date = Date(),
        serverUpdatedAt: Date? = nil
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
        self.actualFinishTime = actualFinishTime
        self.linkedRunId = linkedRunId
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.forecastedWeatherData = forecastedWeatherData
        self.courseRouteData = courseRouteData
        self.savedRouteId = savedRouteId
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
    }
}
