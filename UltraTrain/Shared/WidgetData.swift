import Foundation

struct WidgetSessionData: Codable, Sendable {
    let sessionType: String
    let sessionIcon: String
    let displayName: String
    let description: String
    let plannedDistanceKm: Double
    let plannedElevationGainM: Double
    let plannedDuration: TimeInterval
    let intensity: String
    let date: Date
}

struct WidgetRaceData: Codable, Sendable {
    let name: String
    let date: Date
    let distanceKm: Double
    let elevationGainM: Double
    let planCompletionPercent: Double
}

struct WidgetWeeklyProgressData: Codable, Sendable {
    let actualDistanceKm: Double
    let targetDistanceKm: Double
    let actualElevationGainM: Double
    let targetElevationGainM: Double
    let phase: String
    let weekNumber: Int
}

struct WidgetLastRunData: Codable, Sendable {
    let date: Date
    let distanceKm: Double
    let elevationGainM: Double
    let duration: TimeInterval
    let averagePaceSecondsPerKm: Double
    let averageHeartRate: Int?
}
