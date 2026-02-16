import Foundation

struct ElevationProfilePoint: Identifiable, Equatable, Sendable {
    let id = UUID()
    var distanceKm: Double
    var altitudeM: Double
}

struct HeartRateZoneDistribution: Identifiable, Equatable, Sendable {
    var id: Int { zone }
    var zone: Int
    var zoneName: String
    var durationSeconds: TimeInterval
    var percentage: Double
}

struct RouteSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var coordinates: [(Double, Double)]
    var paceSecondsPerKm: Double
    var kilometerNumber: Int

    static func == (lhs: RouteSegment, rhs: RouteSegment) -> Bool {
        lhs.id == rhs.id
    }
}

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
