import Foundation

enum StrengthTrainingPreference: String, CaseIterable, Sendable, Codable {
    case yes
    case no

    var displayName: String {
        switch self {
        case .yes: String(localized: "stp.yes", defaultValue: "Yes, include it")
        case .no:  String(localized: "stp.no", defaultValue: "No, running only")
        }
    }
}
