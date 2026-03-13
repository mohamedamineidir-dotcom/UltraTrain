import Foundation

enum VerticalGainEnvironment: String, CaseIterable, Sendable, Codable {
    case mountain
    case hill
    case treadmill
    case mixed

    var displayName: String {
        switch self {
        case .mountain:  "Mountain / Trail"
        case .hill:      "Hill"
        case .treadmill: "Treadmill"
        case .mixed:     "Mixed"
        }
    }
}
