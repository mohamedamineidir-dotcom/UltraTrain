import Foundation

struct WatchCompletedRunData: Codable, Sendable {
    let runId: UUID
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var duration: TimeInterval
    var pausedDuration: TimeInterval
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var averagePaceSecondsPerKm: Double
    var trackPoints: [WatchTrackPoint]
    var splits: [WatchSplit]
    var linkedSessionId: UUID?
}
