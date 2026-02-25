import Foundation

enum IntervalPhaseType: String, CaseIterable, Sendable, Codable {
    case warmUp
    case work
    case recovery
    case coolDown

    var displayName: String {
        switch self {
        case .warmUp: return "Warm Up"
        case .work: return "Work"
        case .recovery: return "Recovery"
        case .coolDown: return "Cool Down"
        }
    }

    var iconName: String {
        switch self {
        case .warmUp: return "flame.fill"
        case .work: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .coolDown: return "snowflake"
        }
    }
}
