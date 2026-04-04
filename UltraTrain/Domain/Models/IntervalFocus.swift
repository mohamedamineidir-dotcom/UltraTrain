import Foundation

enum IntervalFocus: String, CaseIterable, Sendable, Codable {
    case uphill
    case speed
    case mixed

    var displayName: String {
        switch self {
        case .uphill: String(localized: "intervalFocus.uphill", defaultValue: "Climbing strength")
        case .speed: String(localized: "intervalFocus.speed", defaultValue: "Flat speed")
        case .mixed: String(localized: "intervalFocus.mixed", defaultValue: "Both equally")
        }
    }

    var subtitle: String {
        switch self {
        case .uphill: "Prioritize uphill intervals and climbing-specific work."
        case .speed: "Prioritize flat speed intervals and running economy."
        case .mixed: "Balanced mix of climbing and speed sessions."
        }
    }

    var icon: String {
        switch self {
        case .uphill: "arrow.up.right"
        case .speed: "bolt.fill"
        case .mixed: "arrow.left.arrow.right"
        }
    }
}
