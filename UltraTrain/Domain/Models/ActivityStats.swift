import Foundation

struct ActivityStats: Equatable, Sendable {
    var distanceKm: Double?
    var elevationGainM: Double?
    var duration: TimeInterval?
    var averagePace: Double?
}
