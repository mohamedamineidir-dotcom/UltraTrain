import Foundation

struct WatchRunData: Codable, Sendable {
    let runState: String
    let elapsedTime: TimeInterval
    let distanceKm: Double
    let currentPace: String
    let currentHeartRate: Int?
    let elevationGainM: Double
    let formattedTime: String
    let formattedDistance: String
    let formattedElevation: String
    let isAutoPaused: Bool
    let activeReminderMessage: String?
    let activeReminderType: String?
}
