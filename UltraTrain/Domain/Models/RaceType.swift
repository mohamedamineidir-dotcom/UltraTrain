import Foundation

enum RaceType: String, CaseIterable, Sendable, Codable {
    case road
    case trail

    var displayName: String {
        switch self {
        case .road: "Road"
        case .trail: "Trail"
        }
    }
}
