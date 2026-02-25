import Foundation

struct PlanComparison: Equatable, Sendable {
    var plannedDistanceKm: Double
    var actualDistanceKm: Double
    var plannedElevationGainM: Double
    var actualElevationGainM: Double
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval
    var plannedPaceSecondsPerKm: Double
    var actualPaceSecondsPerKm: Double
    var sessionType: SessionType
    var sessionDescription: String
}
