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
        case .running: return "Running"
        case .trailRunning: return "Trail Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .strength: return "Strength"
        case .yoga: return "Yoga"
        case .other: return "Other"
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
