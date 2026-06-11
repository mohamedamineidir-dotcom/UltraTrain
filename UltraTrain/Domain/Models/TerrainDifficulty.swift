import Foundation

enum TerrainDifficulty: String, CaseIterable, Sendable, Codable {
    case easy
    case moderate
    case technical
    case extreme

    var displayName: String {
        switch self {
        case .easy:      String(localized: "terrain.easy", defaultValue: "Easy")
        case .moderate:  String(localized: "terrain.moderate", defaultValue: "Moderate")
        case .technical: String(localized: "terrain.technical", defaultValue: "Technical")
        case .extreme:   String(localized: "terrain.extreme", defaultValue: "Extreme")
        }
    }
}
