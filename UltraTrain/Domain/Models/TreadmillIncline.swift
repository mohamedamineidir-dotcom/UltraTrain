import Foundation

enum TreadmillIncline: String, CaseIterable, Sendable, Codable {
    case low
    case medium
    case high
    case veryHigh

    var displayName: String {
        switch self {
        case .low:      "2–6%"
        case .medium:   "6–10%"
        case .high:     "10–15%"
        case .veryHigh: "16%+"
        }
    }
}
