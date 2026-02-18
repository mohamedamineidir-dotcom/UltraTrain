import Foundation

struct WatchTrackPoint: Codable, Sendable, Equatable {
    var latitude: Double
    var longitude: Double
    var altitudeM: Double
    var timestamp: Date
    var heartRate: Int?
}
