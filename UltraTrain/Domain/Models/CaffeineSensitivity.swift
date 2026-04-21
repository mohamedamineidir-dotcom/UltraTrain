import Foundation

/// Athlete's tolerance for caffeine — scales the total race-day caffeine dose
/// from the ISSN 3-6 mg/kg range.
///
/// Research basis: ISSN 2021 position stand — effective range is 3-6 mg/kg,
/// but habitual users tolerate the upper end while non-users may experience
/// jitters or GI issues above 3 mg/kg. Athletes who consume 0 mg/day chronically
/// should start at ~1.5 mg/kg to avoid side effects.
enum CaffeineSensitivity: String, CaseIterable, Codable, Sendable {
    case none       // Avoid entirely
    case low        // Non-habitual, prone to jitters
    case moderate   // Standard — 1-2 cups coffee/day
    case high       // Habitual, tolerates 6 mg/kg

    var displayName: String {
        switch self {
        case .none:     "No caffeine"
        case .low:      "Low (new to caffeine)"
        case .moderate: "Moderate (1-2 coffees/day)"
        case .high:     "High (3+ coffees/day)"
        }
    }

    /// Target mg/kg body weight for race-day total caffeine.
    var targetMgPerKg: Double {
        switch self {
        case .none:     0.0
        case .low:      2.0
        case .moderate: 4.0
        case .high:     5.5
        }
    }
}
