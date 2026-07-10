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
    var raceTypeRaw: String = "trail"
    @Relationship(deleteRule: .cascade, inverse: \CheckpointSwiftDataModel.race)
    var checkpointModels: [CheckpointSwiftDataModel] = []
    var actualFinishTime: Double?
    var linkedRunId: UUID?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationName: String?
    @Attribute(.externalStorage) var forecastedWeatherData: Data?
    @Attribute(.externalStorage) var courseRouteData: Data?
    var savedRouteId: UUID?
    var updatedAt: Date = Date()
    var serverUpdatedAt: Date?
    /// Highest course elevation in meters. Drives altitude-prep
    /// advisory when ≥ 2500m. Optional; nil = no advisory fires.
    var maxElevationM: Double?
    /// Whether trekking poles are allowed on the course. Drives the
    /// pole-training cue. Optional; nil = no cue.
    var polesAllowed: Bool?
    /// Athlete opted into B/C-race specific prep. Default false.
    var includesSpecificPrep: Bool = false
    /// Athlete-entered reference finish times for this course (last
    /// edition's winner / typical finisher), used to calibrate course
    /// difficulty in the finish-time estimator. Optional; nil = not given.
    var referenceWinnerTimeSeconds: Double?
    var referenceMedianTimeSeconds: Double?

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
        raceTypeRaw: String = "trail",
        checkpointModels: [CheckpointSwiftDataModel] = [],
        actualFinishTime: Double? = nil,
        linkedRunId: UUID? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationName: String? = nil,
        forecastedWeatherData: Data? = nil,
        courseRouteData: Data? = nil,
        savedRouteId: UUID? = nil,
        updatedAt: Date = Date(),
        serverUpdatedAt: Date? = nil,
        maxElevationM: Double? = nil,
        polesAllowed: Bool? = nil,
        includesSpecificPrep: Bool = false,
        referenceWinnerTimeSeconds: Double? = nil,
        referenceMedianTimeSeconds: Double? = nil
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
        self.raceTypeRaw = raceTypeRaw
        self.checkpointModels = checkpointModels
        self.actualFinishTime = actualFinishTime
        self.linkedRunId = linkedRunId
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationName = locationName
        self.forecastedWeatherData = forecastedWeatherData
        self.courseRouteData = courseRouteData
        self.savedRouteId = savedRouteId
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
        self.maxElevationM = maxElevationM
        self.polesAllowed = polesAllowed
        self.includesSpecificPrep = includesSpecificPrep
        self.referenceWinnerTimeSeconds = referenceWinnerTimeSeconds
        self.referenceMedianTimeSeconds = referenceMedianTimeSeconds
    }
}
