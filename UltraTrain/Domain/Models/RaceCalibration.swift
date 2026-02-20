import Foundation

struct RaceCalibration: Sendable {
    let raceId: UUID
    let predictedTime: TimeInterval
    let actualTime: TimeInterval
    let raceDistanceKm: Double
    let raceElevationGainM: Double
}
