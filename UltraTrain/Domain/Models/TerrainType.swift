import Foundation

enum TerrainType: String, CaseIterable, Sendable, Codable {
    case road
    case trail
    case mixed

    var displayName: String {
        switch self {
        case .road:  "Road"
        case .trail: "Trail"
        case .mixed: "Mixed"
        }
    }
}
