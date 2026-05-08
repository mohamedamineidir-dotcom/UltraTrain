import Foundation

struct TrainingPlan: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var athleteId: UUID
    var targetRaceId: UUID
    var createdAt: Date
    var weeks: [TrainingWeek]
    var intermediateRaceIds: [UUID]
    var intermediateRaceSnapshots: [RaceSnapshot]
    var workouts: [IntervalWorkout] = []
    var strengthWorkouts: [StrengthWorkout] = []
    /// Baseline VMA captured at the moment a regression-pending
    /// confirmation re-test was scheduled. Used so the second test
    /// compares against the PRE-test fitness anchor, not the post-
    /// first-test value (which has already been updated to the
    /// regressed result). Cleared once the re-test completes.
    var pendingRetestOriginalBaselineVma: Double? = nil

    var totalWeeks: Int { weeks.count }
    var currentWeekIndex: Int? {
        weeks.firstIndex { $0.containsToday }
    }
}
