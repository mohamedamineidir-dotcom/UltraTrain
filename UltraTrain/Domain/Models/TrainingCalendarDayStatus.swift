import Foundation

enum TrainingCalendarDayStatus: Equatable, Sendable {
    case noActivity
    case rest
    case planned(sessionCount: Int)
    case completed(sessionCount: Int)
    case partial(completed: Int, total: Int)
    case ranWithoutPlan
}
