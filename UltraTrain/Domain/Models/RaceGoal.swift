import Foundation

enum RaceGoal: Equatable, Sendable, Codable {
    case finish
    case targetTime(TimeInterval)
    case targetRanking(Int)
}
