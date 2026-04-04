import Foundation

enum VerticalGainEnvironment: String, CaseIterable, Sendable, Codable {
    case mountain
    case hill
    case treadmill
    case stairs
    case mixed

    var displayName: String {
        switch self {
        case .mountain:  "Mountain / Trail"
        case .hill:      "Hill"
        case .treadmill: "Treadmill"
        case .stairs:    "Stairs only"
        case .mixed:     "Mixed"
        }
    }

    var hasOutdoorHill: Bool {
        self == .mountain || self == .hill || self == .mixed
    }

    var hasTreadmill: Bool {
        self == .treadmill || self == .mixed
    }

    var hasStairs: Bool {
        self == .stairs
    }
}
