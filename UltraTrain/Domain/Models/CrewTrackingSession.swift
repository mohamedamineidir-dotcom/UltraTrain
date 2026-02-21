import Foundation

enum CrewTrackingStatus: String, Sendable {
    case active
    case paused
    case ended
}

struct CrewTrackingSession: Identifiable, Equatable, Sendable {
    let id: UUID
    var hostProfileId: String
    var hostDisplayName: String
    var startedAt: Date
    var status: CrewTrackingStatus
    var participants: [CrewParticipant]
}

struct CrewParticipant: Identifiable, Equatable, Sendable {
    let id: String
    var displayName: String
    var latitude: Double
    var longitude: Double
    var distanceKm: Double
    var currentPaceSecondsPerKm: Double
    var lastUpdated: Date
}
