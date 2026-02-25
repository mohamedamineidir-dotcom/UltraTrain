import Foundation

struct GroupChallenge: Identifiable, Equatable, Sendable {
    let id: UUID
    var creatorProfileId: String
    var creatorDisplayName: String
    var name: String
    var descriptionText: String
    var type: ChallengeType
    var targetValue: Double
    var startDate: Date
    var endDate: Date
    var status: GroupChallengeStatus
    var participants: [GroupChallengeParticipant]

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date.now, to: endDate).day ?? 0)
    }

    var unitLabel: String {
        switch type {
        case .distance: return "km"
        case .elevation: return "m D+"
        case .consistency: return "runs"
        case .streak: return "days"
        }
    }
}
