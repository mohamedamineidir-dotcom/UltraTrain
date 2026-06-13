import Foundation

enum RaceGoalSelection: String, CaseIterable, Sendable {
    case finish
    case targetTime
    case targetRanking

    var displayName: String {
        switch self {
        case .finish: return String(localized: "raceGoal.finish", defaultValue: "Finish")
        case .targetTime: return String(localized: "raceGoal.targetTime", defaultValue: "Target Time")
        case .targetRanking: return String(localized: "raceGoal.targetRanking", defaultValue: "Target Ranking")
        }
    }
}
