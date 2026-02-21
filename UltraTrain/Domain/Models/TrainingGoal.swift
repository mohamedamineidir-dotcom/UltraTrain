import Foundation

struct TrainingGoal: Identifiable, Equatable, Sendable {
    let id: UUID
    var period: GoalPeriod
    var targetDistanceKm: Double?
    var targetElevationM: Double?
    var targetRunCount: Int?
    var targetDurationSeconds: TimeInterval?
    var startDate: Date
    var endDate: Date
}
