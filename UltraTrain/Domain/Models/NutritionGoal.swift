import Foundation

/// Primary nutrition goal — drives how aggressive the race-day plan is.
///
/// Research basis: a finish-focused runner prioritizes GI safety and finishes
/// comfortably at 45-60 g/hr, while a competitive runner needs 80-100+ g/hr
/// to hit target splits. Goals shift the carb-per-hour target ±10% from the
/// duration-based baseline.
enum NutritionGoal: String, CaseIterable, Codable, Sendable {
    /// Prioritize GI safety and comfort. Conservative carb and caffeine targets.
    case finishComfortably
    /// Hit a specific time. Standard evidence-based targets.
    case targetTime
    /// Race for placing. Aggressive carb intake (requires gut training).
    case competitive

    var displayName: String {
        switch self {
        case .finishComfortably: "Finish comfortably"
        case .targetTime:        "Target time"
        case .competitive:       "Competitive"
        }
    }

    /// Multiplier applied to the duration-based carb-per-hour target.
    var carbsPerHourMultiplier: Double {
        switch self {
        case .finishComfortably: 0.85
        case .targetTime:        1.00
        case .competitive:       1.10
        }
    }
}
