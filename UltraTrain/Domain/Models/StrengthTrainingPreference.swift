import Foundation

enum StrengthTrainingPreference: String, CaseIterable, Sendable, Codable {
    case yes
    case no

    var displayName: String {
        switch self {
        case .yes: "Yes, include it"
        case .no:  "No, running only"
        }
    }
}
