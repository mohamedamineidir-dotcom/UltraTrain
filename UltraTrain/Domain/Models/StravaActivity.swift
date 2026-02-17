import Foundation

struct StravaActivity: Identifiable, Sendable {
    let id: Int
    let name: String
    let type: String
    let startDate: Date
    let distanceMeters: Double
    let movingTimeSeconds: Int
    let totalElevationGain: Double
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    var isImported: Bool = false

    var distanceKm: Double { distanceMeters / 1000.0 }

    var formattedDuration: String {
        let hours = movingTimeSeconds / 3600
        let minutes = (movingTimeSeconds % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}
