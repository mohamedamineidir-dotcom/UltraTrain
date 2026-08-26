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
        // The 100K/100 Miles boundary sits at 161 km — the actual distance
        // of a 100-mile race (160.9 km) — not some lower "effective km"
        // figure. A hilly 100K (e.g. 100 km + 5000 m D+ = 150 km
        // effective under the +1km-per-100m-D+ rule) previously crossed
        // the old 140 km boundary and got bucketed as a 100 Miler, which
        // then demanded that category's higher minimum prep weeks — a
        // real 100K race being blocked from onboarding by the app's own
        // misclassification, not by an actually-insufficient prep window.
        switch effectiveDistanceKm {
        case ..<42: .trail
        case 42..<80: .fiftyK
        case 80..<161: .hundredK
        case 161..<220: .hundredMiles
        default: .ultraLong
        }
    }
}
