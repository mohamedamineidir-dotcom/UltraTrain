import Foundation

struct CrewParticipant: Identifiable, Equatable, Sendable {
    let id: String
    var displayName: String
    var latitude: Double
    var longitude: Double
    var distanceKm: Double
    var currentPaceSecondsPerKm: Double
    var lastUpdated: Date
}
