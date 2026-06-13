import Foundation

enum PainFrequency: String, CaseIterable, Sendable, Codable {
    case never
    case rarely
    case sometimes
    case often

    var displayName: String {
        switch self {
        case .never:     String(localized: "pain.never", defaultValue: "No pain")
        case .rarely:    String(localized: "pain.rarely", defaultValue: "Rarely (few times a year)")
        case .sometimes: String(localized: "pain.sometimes", defaultValue: "Sometimes (monthly)")
        case .often:     String(localized: "pain.often", defaultValue: "Often (weekly)")
        }
    }
}
