import Foundation

enum RaceCategory: String, Sendable, CaseIterable {
    case trail
    case fiftyK
    case hundredK
    case hundredMiles
    case ultraLong

    var displayName: String {
        switch self {
        case .trail: "Trail (<42 km eff.)"
        case .fiftyK: "50K"
        case .hundredK: "100K"
        case .hundredMiles: "100 Miles"
        case .ultraLong: "Ultra Long"
        }
    }

    static func from(effectiveDistanceKm: Double) -> RaceCategory {
        switch effectiveDistanceKm {
        case ..<42: .trail
        case 42..<80: .fiftyK
        case 80..<140: .hundredK
        case 140..<220: .hundredMiles
        default: .ultraLong
        }
    }
}
