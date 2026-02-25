import Foundation

struct CrewTrackingSession: Identifiable, Equatable, Sendable {
    let id: UUID
    var hostProfileId: String
    var hostDisplayName: String
    var startedAt: Date
    var status: CrewTrackingStatus
    var participants: [CrewParticipant]
}
