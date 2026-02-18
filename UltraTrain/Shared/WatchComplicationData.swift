import Foundation

struct WatchComplicationData: Codable, Sendable {
    var nextSessionType: String?
    var nextSessionDistanceKm: Double?
    var nextSessionDate: Date?
    var raceCountdownDays: Int?
    var raceName: String?
}
