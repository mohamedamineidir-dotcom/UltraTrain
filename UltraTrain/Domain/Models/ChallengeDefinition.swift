import Foundation

struct ChallengeDefinition: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var descriptionText: String
    var type: ChallengeType
    var targetValue: Double
    var duration: ChallengeDuration
    var iconName: String

    var unitLabel: String {
        switch type {
        case .distance: return "km"
        case .elevation: return "m D+"
        case .consistency: return "runs/week"
        case .streak: return "days"
        }
    }
}
