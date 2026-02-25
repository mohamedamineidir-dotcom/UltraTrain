import Foundation

struct GroupChallengeParticipant: Identifiable, Equatable, Sendable {
    let id: String
    var displayName: String
    var photoData: Data?
    var currentValue: Double
    var joinedDate: Date

    var progressPercent: Double {
        0
    }
}
