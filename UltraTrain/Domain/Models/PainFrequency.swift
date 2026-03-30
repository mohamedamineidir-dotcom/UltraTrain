import Foundation

enum PainFrequency: String, CaseIterable, Sendable, Codable {
    case never
    case rarely
    case sometimes
    case often

    var displayName: String {
        switch self {
        case .never:     "No pain"
        case .rarely:    "Rarely (few times a year)"
        case .sometimes: "Sometimes (monthly)"
        case .often:     "Often (weekly)"
        }
    }
}
