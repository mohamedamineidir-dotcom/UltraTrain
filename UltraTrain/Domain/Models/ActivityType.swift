import Foundation

enum ActivityType: String, CaseIterable, Sendable, Codable {
    case running
    case trailRunning
    case cycling
    case swimming
    case hiking
    case strength
    case yoga
    case other

    var displayName: String {
        switch self {
        case .running: return String(localized: "atype.running", defaultValue: "Running")
        case .trailRunning: return String(localized: "atype.trail", defaultValue: "Trail Running")
        case .cycling: return String(localized: "atype.cycling", defaultValue: "Cycling")
        case .swimming: return String(localized: "atype.swimming", defaultValue: "Swimming")
        case .hiking: return String(localized: "atype.hiking", defaultValue: "Hiking")
        case .strength: return String(localized: "atype.strength", defaultValue: "Strength")
        case .yoga: return String(localized: "atype.yoga", defaultValue: "Yoga")
        case .other: return String(localized: "atype.other", defaultValue: "Other")
        }
    }

    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .trailRunning: return "figure.hiking"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .other: return "figure.mixed.cardio"
        }
    }

    var isGPSActivity: Bool {
        switch self {
        case .running, .trailRunning, .cycling, .hiking:
            return true
        case .swimming, .strength, .yoga, .other:
            return false
        }
    }

    var isDistanceBased: Bool {
        switch self {
        case .running, .trailRunning, .cycling, .hiking, .swimming:
            return true
        case .strength, .yoga, .other:
            return false
        }
    }
}
