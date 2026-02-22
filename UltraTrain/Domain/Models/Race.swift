import Foundation

struct Race: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var priority: RacePriority
    var goalType: RaceGoal
    var checkpoints: [Checkpoint]
    var terrainDifficulty: TerrainDifficulty
    var actualFinishTime: TimeInterval?
    var linkedRunId: UUID?
    var locationLatitude: Double? = nil
    var locationLongitude: Double? = nil
    var forecastedWeather: WeatherSnapshot? = nil
    var courseRoute: [TrackPoint] = []
    var savedRouteId: UUID? = nil

    var hasCourseRoute: Bool { !courseRoute.isEmpty }

    var isCompleted: Bool { actualFinishTime != nil }

    var hasLocation: Bool {
        locationLatitude != nil && locationLongitude != nil
    }

    var effectiveDistanceKm: Double {
        distanceKm + (elevationGainM / 100.0)
    }
}

enum RacePriority: String, CaseIterable, Codable, Sendable {
    case aRace
    case bRace
    case cRace
}

enum RaceGoal: Equatable, Sendable {
    case finish
    case targetTime(TimeInterval)
    case targetRanking(Int)
}

enum TerrainDifficulty: String, CaseIterable, Sendable {
    case easy
    case moderate
    case technical
    case extreme
}

struct Checkpoint: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var distanceFromStartKm: Double
    var elevationM: Double
    var hasAidStation: Bool
}
