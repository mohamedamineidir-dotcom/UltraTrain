import Foundation

enum ExperienceLevel: String, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced
    case elite

    var displayName: String {
        switch self {
        case .beginner:     String(localized: "experience.beginner", defaultValue: "Beginner")
        case .intermediate: String(localized: "experience.intermediate", defaultValue: "Intermediate")
        case .advanced:     String(localized: "experience.advanced", defaultValue: "Advanced")
        case .elite:        String(localized: "experience.elite", defaultValue: "Elite")
        }
    }
}
