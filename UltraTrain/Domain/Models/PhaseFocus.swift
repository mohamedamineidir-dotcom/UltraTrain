import Foundation

enum PhaseFocus: String, CaseIterable, Sendable, Codable {
    case threshold30
    case vo2max
    case threshold60
    case sharpening
    case postRaceRecovery

    var displayName: String {
        displayName(isRoad: false)
    }

    func displayName(isRoad: Bool) -> String {
        if isRoad {
            return switch self {
            case .threshold30:      String(localized: "phase.road.foundation", defaultValue: "Aerobic foundation")
            case .vo2max:           String(localized: "phase.road.thresholdVo2", defaultValue: "Threshold & VO2max")
            case .threshold60:      String(localized: "phase.road.raceSpecific", defaultValue: "Race-specific block")
            case .sharpening:       String(localized: "phase.road.taper", defaultValue: "Race taper")
            case .postRaceRecovery: String(localized: "phase.road.postRace", defaultValue: "Post-race recovery")
            }
        }
        return switch self {
        case .threshold30:      String(localized: "phase.trail.threshold30", defaultValue: "30' Threshold")
        case .vo2max:           String(localized: "phase.trail.vo2max", defaultValue: "VO2max Hills")
        case .threshold60:      String(localized: "phase.trail.threshold60", defaultValue: "60' Threshold")
        case .sharpening:       String(localized: "phase.trail.sharpening", defaultValue: "Sharpening")
        case .postRaceRecovery: String(localized: "phase.trail.postRace", defaultValue: "Post-Race Recovery")
        }
    }

    var shortDescription: String {
        shortDescription(isRoad: false)
    }

    func shortDescription(isRoad: Bool) -> String {
        if isRoad {
            return switch self {
            case .threshold30:
                String(localized: "phase.road.foundation.desc",
                       defaultValue: "Aerobic capacity with easy mileage and strides")
            case .vo2max:
                String(localized: "phase.road.thresholdVo2.desc",
                       defaultValue: "Threshold blocks and VO2max intervals to sharpen the engine")
            case .threshold60:
                String(localized: "phase.road.raceSpecific.desc",
                       defaultValue: "Race-pace blocks and race-specific endurance")
            case .sharpening:
                String(localized: "phase.road.taper.desc",
                       defaultValue: "Volume reduction with race-pace sharpeners")
            case .postRaceRecovery:
                String(localized: "phase.road.postRace.desc",
                       defaultValue: "Active recovery and adaptation after competition")
            }
        }
        return switch self {
        case .threshold30:
            String(localized: "phase.trail.threshold30.desc",
                   defaultValue: "Build aerobic power with 30-minute threshold efforts on hills")
        case .vo2max:
            String(localized: "phase.trail.vo2max.desc",
                   defaultValue: "VO2max intervals on steep climbs, short, intense hill repeats")
        case .threshold60:
            String(localized: "phase.trail.threshold60.desc",
                   defaultValue: "Sustained 60-minute threshold on rolling terrain, race-specific endurance")
        case .sharpening:
            String(localized: "phase.trail.sharpening.desc",
                   defaultValue: "Volume reduction and race-day sharpening")
        case .postRaceRecovery:
            String(localized: "phase.trail.postRace.desc",
                   defaultValue: "Active recovery and adaptation after competition")
        }
    }
}
