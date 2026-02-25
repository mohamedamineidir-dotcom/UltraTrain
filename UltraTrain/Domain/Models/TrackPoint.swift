import Foundation

struct TrackPoint: Equatable, Sendable, Codable {
    var latitude: Double
    var longitude: Double
    var altitudeM: Double
    var timestamp: Date
    var heartRate: Int?
}
