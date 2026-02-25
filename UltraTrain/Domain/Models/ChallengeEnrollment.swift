import Foundation

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
