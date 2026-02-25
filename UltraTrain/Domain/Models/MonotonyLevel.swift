import Foundation

enum MonotonyLevel: String, Sendable {
    case low
    case normal
    case high

    init(monotony: Double) {
        if monotony > 2.0 {
            self = .high
        } else if monotony >= 1.5 {
            self = .normal
        } else {
            self = .low
        }
    }

    var displayName: String {
        switch self {
        case .low: "Good Variety"
        case .normal: "Normal"
        case .high: "Too Monotonous"
        }
    }
}
