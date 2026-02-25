import Foundation

enum FeedActivityType: String, Sendable, CaseIterable {
    case completedRun
    case personalRecord
    case challengeCompleted
    case raceFinished
    case weeklyGoalMet
    case friendJoined
}
