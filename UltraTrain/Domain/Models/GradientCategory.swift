import Foundation

enum GradientCategory: String, CaseIterable, Sendable {
    case steepDown
    case moderateDown
    case flat
    case moderateUp
    case steepUp

    static func from(gradient: Double) -> GradientCategory {
        switch gradient {
        case ..<(-15): .steepDown
        case -15 ..< -5: .moderateDown
        case -5 ..< 5: .flat
        case 5 ..< 15: .moderateUp
        default: .steepUp
        }
    }
}
