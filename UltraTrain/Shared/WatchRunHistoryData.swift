import Foundation

struct WatchRunHistoryData: Codable, Sendable, Identifiable {
    let id: UUID
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval
    var averagePaceSecondsPerKm: Double
    var averageHeartRate: Int?
}
