import Foundation

enum AchievementRequirement: Equatable, Sendable {
    case totalDistanceKm(Double)
    case totalElevationM(Double)
    case singleRunDistanceKm(Double)
    case singleRunElevationM(Double)
    case totalRuns(Int)
    case streakDays(Int)
    case completedRace
    case completedRaces(Int)
    case completedChallenge(Int)
    case personalRecord
}
