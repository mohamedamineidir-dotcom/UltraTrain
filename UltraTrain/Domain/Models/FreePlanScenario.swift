import Foundation

/// The two fixed training-plan scenarios available to free-tier users.
/// Each generates a personalized 12-week road plan (adapted to the
/// athlete's experience, volume and paces); free users pick one of these
/// instead of building a custom race plan, which is premium.
enum FreePlanScenario: String, CaseIterable, Sendable, Identifiable, Codable {
    /// 12-week general-fitness return to running, no race goal.
    case comeback
    /// 12-week preparation for a 5K race.
    case fiveK

    var id: String { rawValue }
}
