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
        case .trailSpecific: return "Trail Specific"
        case .speedWork: return "Speed Work"
        case .hillTraining: return "Hill Training"
        case .recovery: return "Recovery"
        case .racePrep: return "Race Prep"
        case .roadSpecific: return "Road Specific"
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
