import Foundation

enum AchievementCategory: String, CaseIterable, Sendable {
    case distance
    case elevation
    case consistency
    case speed
    case race
    case milestone

    var displayName: String {
        switch self {
        case .distance: "Distance"
        case .elevation: "Elevation"
        case .consistency: "Consistency"
        case .speed: "Speed"
        case .race: "Race"
        case .milestone: "Milestone"
        }
    }
}
