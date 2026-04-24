import Foundation

/// How long before race start the athlete prefers to eat the pre-race
/// meal. Jeukendrup (ISSN 2017) recommends 1-4 g/kg carb 1-4 hours
/// before — the athlete's own window within that range drives the
/// pre-race meal card in `RaceFuellingProtocolGenerator`.
///
/// Only asked for races ≥ 90 min of effort (HM and up) — shorter
/// races don't meaningfully benefit from glycogen-loading the morning
/// of, so the timing choice doesn't change the prescription.
enum PreRaceMealTiming: String, CaseIterable, Codable, Sendable {
    /// Tight window — the athlete eats 60-90 min out. Smaller meal,
    /// lower fat + fibre, more liquid calories. Common for early-start
    /// races when the athlete doesn't want a 4am wake-up.
    case oneHour
    /// The "most common" window for recreational runners. Allows a
    /// moderate carb load with familiar foods.
    case twoHours
    /// Traditional endurance timing. Full carb meal has time to settle,
    /// GI risk is lowest. Standard recommendation.
    case threeHours
    /// Long-window — the athlete sets an alarm to eat early, then goes
    /// back to bed or stays up. Used by elite athletes and by those with
    /// slow digestion.
    case fourHours

    var displayName: String {
        switch self {
        case .oneHour:    return "1 hour before"
        case .twoHours:   return "2 hours before"
        case .threeHours: return "3 hours before"
        case .fourHours:  return "4 hours before"
        }
    }

    var subtitle: String {
        switch self {
        case .oneHour:
            return "Tight window — lighter meal, mostly liquid calories"
        case .twoHours:
            return "Most common — moderate meal, familiar foods"
        case .threeHours:
            return "Traditional — full carb meal, lowest GI risk"
        case .fourHours:
            return "Long window — full meal, early wake-up"
        }
    }

    var hoursBefore: Double {
        switch self {
        case .oneHour:    return 1
        case .twoHours:   return 2
        case .threeHours: return 3
        case .fourHours:  return 4
        }
    }
}
