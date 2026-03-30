import Foundation

enum StrengthTrainingLocation: String, CaseIterable, Sendable, Codable {
    case gym
    case home

    var displayName: String {
        switch self {
        case .gym:  "Gym (equipment available)"
        case .home: "Home (bodyweight / bands)"
        }
    }
}
