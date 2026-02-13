import Foundation

enum RaceGoalSelection: String, CaseIterable, Sendable {
    case finish
    case targetTime
    case targetRanking

    var displayName: String {
        switch self {
        case .finish: return "Finish"
        case .targetTime: return "Target Time"
        case .targetRanking: return "Target Ranking"
        }
    }
}
