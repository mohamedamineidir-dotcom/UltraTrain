import Foundation

struct CoachingInsight: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: CoachingInsightType
    var category: InsightCategory
    var title: String
    var message: String
    var icon: String
}

enum CoachingInsightType: String, Sendable {
    case formPeaking
    case readyToRace
    case recoveryNeeded
    case taperGuidance
    case raceWeek
    case phaseTransition
    case consistentTraining
    case volumeOnTrack
    case longRunReminder
    case detrainingRisk
    case poorSleepRecovery
    case sleepDeficit
    case goodRecovery
}

enum InsightCategory: String, Sendable {
    case positive
    case guidance
    case warning
}
