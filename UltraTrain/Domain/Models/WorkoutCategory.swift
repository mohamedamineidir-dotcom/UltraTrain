import Foundation

enum WorkoutCategory: String, CaseIterable, Sendable, Codable {
    case trailSpecific
    case speedWork
    case hillTraining
    case recovery
    case racePrep
    case roadSpecific

    var displayName: String {
        switch self {
        case .trailSpecific: return String(localized: "wcat.trail", defaultValue: "Trail Specific")
        case .speedWork: return String(localized: "wcat.speed", defaultValue: "Speed Work")
        case .hillTraining: return String(localized: "wcat.hill", defaultValue: "Hill Training")
        case .recovery: return String(localized: "wcat.recovery", defaultValue: "Recovery")
        case .racePrep: return String(localized: "wcat.racePrep", defaultValue: "Race Prep")
        case .roadSpecific: return String(localized: "wcat.road", defaultValue: "Road Specific")
        }
    }

    var iconName: String {
        switch self {
        case .trailSpecific: return "leaf.fill"
        case .speedWork: return "speedometer"
        case .hillTraining: return "mountain.2.fill"
        case .recovery: return "bed.double.fill"
        case .racePrep: return "flag.checkered"
        case .roadSpecific: return "figure.run"
        }
    }
}
