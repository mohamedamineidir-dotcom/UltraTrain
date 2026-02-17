#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct RunActivityAttributes: ActivityAttributes {

    // MARK: - Static Context

    let startTime: Date
    let linkedSessionName: String?

    // MARK: - Dynamic Content

    struct ContentState: Codable, Hashable {
        let elapsedTime: TimeInterval
        let distanceKm: Double
        let currentHeartRate: Int?
        let elevationGainM: Double
        let runState: String
        let isAutoPaused: Bool
        let formattedDistance: String
        let formattedElevation: String
        let formattedPace: String
        let timerStartDate: Date
        let isPaused: Bool
    }
}
#endif
