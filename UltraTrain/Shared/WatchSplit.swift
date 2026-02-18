import Foundation

struct WatchSplit: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    var kilometerNumber: Int
    var duration: TimeInterval
    var elevationChangeM: Double
    var averageHeartRate: Int?
}
