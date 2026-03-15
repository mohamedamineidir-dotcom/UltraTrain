import Foundation

enum PhaseFocus: String, CaseIterable, Sendable, Codable {
    case threshold30
    case vo2max
    case threshold60
    case sharpening
    case postRaceRecovery

    var displayName: String {
        switch self {
        case .threshold30:      "30' Threshold"
        case .vo2max:           "VO2max Hills"
        case .threshold60:      "60' Threshold"
        case .sharpening:       "Sharpening"
        case .postRaceRecovery: "Post-Race Recovery"
        }
    }

    var shortDescription: String {
        switch self {
        case .threshold30:
            "Build aerobic power with 30-minute threshold efforts on hills"
        case .vo2max:
            "VO2max intervals on steep climbs — short, intense hill repeats"
        case .threshold60:
            "Sustained 60-minute threshold on rolling terrain — race-specific endurance"
        case .sharpening:
            "Volume reduction and race-day sharpening"
        case .postRaceRecovery:
            "Active recovery and adaptation after competition"
        }
    }
}
