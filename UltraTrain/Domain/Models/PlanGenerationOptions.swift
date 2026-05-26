import Foundation

/// Plan-time options collected from the small onboarding sheet shown
/// before plan generation. Mirrors the nutrition-plan onboarding
/// pattern. Plan-scoped (not athlete-scoped) so the answers can
/// differ per prep cycle.
struct PlanGenerationOptions: Sendable, Equatable {

    /// Athlete opted in to a mid-prep fitness test. If true, the
    /// scheduler decides whether (and where) to actually insert the
    /// test based on race / plan / collision rules.
    var includeFitnessTest: Bool = false

    /// Athlete reported a meaningful fitness change since the last
    /// profile setup (injury, illness, multi-week break). Used to
    /// dampen the base-anchor multiplier so we don't prescribe
    /// volume the athlete hasn't built up to.
    var recentFitnessChange: RecentFitnessChange? = nil

    static let standard = PlanGenerationOptions()
}

/// Self-reported recent fitness change in the 4 weeks prior to plan
/// generation. Coarse buckets, we just need a directional signal.
enum RecentFitnessChange: String, Sendable, Codable, CaseIterable {
    case none
    case minor       // 1-2 weeks reduced volume from light illness, soreness
    case moderate    // 2-4 weeks off, low-grade injury managed
    case significant // 4+ weeks off, recovering from injury or major illness

    var displayName: String {
        switch self {
        case .none:        "No change, training as usual"
        case .minor:       "Light setback (1-2 weeks reduced)"
        case .moderate:    "Moderate (2-4 weeks off / managed injury)"
        case .significant: "Significant (4+ weeks off, returning)"
        }
    }

    /// Multiplier applied to the base-anchor weekly volume. Damper for
    /// athletes who have lost fitness vs the onboarding snapshot
    /// avoids prescribing a peak load they can't yet handle.
    var anchorMultiplier: Double {
        switch self {
        case .none:        1.00
        case .minor:       0.92
        case .moderate:    0.80
        case .significant: 0.70
        }
    }
}
