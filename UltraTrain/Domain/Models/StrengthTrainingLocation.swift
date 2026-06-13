import Foundation

enum StrengthTrainingLocation: String, CaseIterable, Sendable, Codable {
    case gym
    case home

    var displayName: String {
        switch self {
        case .gym:  String(localized: "stloc.gym", defaultValue: "Gym (equipment available)")
        case .home: String(localized: "stloc.home", defaultValue: "Home (bodyweight / bands)")
        }
    }
}
