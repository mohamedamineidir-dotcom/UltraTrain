import Foundation

struct ElevationProfilePoint: Identifiable, Equatable, Sendable {
    let id = UUID()
    var distanceKm: Double
    var altitudeM: Double
}
