import Foundation

enum ChallengeType: String, CaseIterable, Sendable {
    case distance
    case elevation
    case consistency
    case streak
}

enum ChallengeDuration: String, CaseIterable, Sendable {
    case oneWeek
    case twoWeeks
    case oneMonth

    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        }
    }

    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        }
    }
}

enum ChallengeStatus: String, Sendable {
    case active
    case completed
    case expired
}

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

struct ChallengeEnrollment: Identifiable, Equatable, Sendable {
    let id: UUID
    var challengeDefinitionId: String
    var startDate: Date
    var status: ChallengeStatus
    var completedDate: Date?

    var endDate: Date? {
        guard let definition = ChallengeLibrary.definition(for: challengeDefinitionId) else { return nil }
        return Calendar.current.date(byAdding: .day, value: definition.duration.days, to: startDate)
    }
}
