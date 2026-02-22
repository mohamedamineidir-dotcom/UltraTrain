import Foundation

struct OSMTrailResult: Identifiable, Sendable {
    let id: String
    var name: String
    var distanceKm: Double
    var trackPoints: [TrackPoint]
    var tags: [String: String]
}
