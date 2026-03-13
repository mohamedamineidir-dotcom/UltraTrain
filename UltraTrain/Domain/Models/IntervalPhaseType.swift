import Foundation

enum IntervalPhaseType: String, CaseIterable, Sendable, Codable {
    case warmUp
    case work
    case recovery
    case coolDown

    var displayName: String {
        switch self {
        case .warmUp: return String(localized: "phaseType.warmUp", defaultValue: "Warm Up")
        case .work: return String(localized: "phaseType.work", defaultValue: "Work")
        case .recovery: return String(localized: "phaseType.recovery", defaultValue: "Recovery")
        case .coolDown: return String(localized: "phaseType.coolDown", defaultValue: "Cool Down")
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
