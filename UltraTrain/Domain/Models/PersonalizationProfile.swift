import Foundation

/// Per-athlete multipliers + hard caps that personalize peak training
/// loads beyond the broad strokes of `experience × philosophy × goal ×
/// age × race`. Composed from athlete profile + (in v2) recent
/// training history. All multipliers individually clamped to [0.85,
/// 1.15]; the composite stack is hard-clamped to [0.75, 1.30] so no
/// single signal can blow up the prescription.
///
/// **Default-equivalent**: when the athlete profile yields no
/// personalization signal (a fresh sign-up), every multiplier is 1.0
/// and the hard caps are nil — i.e., the calculators behave exactly
/// as before. The type is therefore safe to thread through with
/// default `nil` parameters across the stack.
struct PersonalizationProfile: Equatable, Sendable {

    // MARK: - Multipliers

    /// Tenure: scales with consistent running years. <1y: 0.92,
    /// 1-3y: 0.95, 3-7y: 1.0, 7-15y: 1.05, 15y+: 1.10.
    let tenureMultiplier: Double

    /// Weight band: <70kg: 1.03, 70-85: 1.00, >85: 0.93. Heavier
    /// athletes carry more impact load on tendons, so peak loads
    /// scale down slightly to reduce injury risk at peak.
    let weightMultiplier: Double

    /// Ultra-distance experience (≥30 km trail finishes). 0 races:
    /// 0.95 (first-timer), 1-2: 1.00, 3-4: 1.05, 5+: 1.10. Only
    /// applied to trail/ultra plans; ignored for road.
    let ultraExperienceMultiplier: Double

    // MARK: - Hard caps

    /// Athlete's longest completed single run, in seconds, capped at
    /// 1.20× to allow modest stretch above demonstrated tolerance.
    /// Nil when no historical longest run is available. Applied as
    /// a `min(...)` on the computed peak single LR.
    let historicalLongRunCapSeconds: TimeInterval?

    // MARK: - Reported injury structures

    /// Recurring injury sites the athlete flagged at onboarding.
    /// Currently surfaced to coach advice; used to dampen volume
    /// caps lightly (-0.5% per structure, max -2%). Will drive
    /// session-selection bias in v2.
    let injuryStructures: Set<InjuryStructure>

    // MARK: - Composite

    /// Convenience: the trail/ultra composite multiplier (tenure ×
    /// weight × ultraExperience), hard-clamped to [0.75, 1.30].
    /// Use this for peak LR / B2B prescriptions in trail plans.
    var trailComposite: Double {
        clamp(tenureMultiplier * weightMultiplier * ultraExperienceMultiplier)
    }

    /// Road composite: tenure × weight only. Ultra experience is
    /// not relevant for road plans (a 100-mile finish does not
    /// directly translate to road readiness).
    var roadComposite: Double {
        clamp(tenureMultiplier * weightMultiplier)
    }

    /// Volume-cap dampening from injury structures. -0.5% per
    /// flagged structure, capped at -2.0%. Returned as a delta to
    /// add to the percentage-based weekly cap (so 18% cap with 2
    /// structures becomes 17%).
    var injuryVolumeCapPenalty: Double {
        let count = min(injuryStructures.count, 4)
        return -0.5 * Double(count)
    }

    private func clamp(_ value: Double) -> Double {
        max(0.75, min(1.30, value))
    }

    // MARK: - Default

    /// Profile that has no effect — all multipliers 1.0, no caps,
    /// no injury structures. Use as fallback when athlete data
    /// yields no signal.
    static let neutral = PersonalizationProfile(
        tenureMultiplier: 1.0,
        weightMultiplier: 1.0,
        ultraExperienceMultiplier: 1.0,
        historicalLongRunCapSeconds: nil,
        injuryStructures: []
    )
}

// MARK: - Factory

extension PersonalizationProfile {

    /// Builds a personalization profile from an athlete. Pace
    /// estimate is used to convert `longestRunKm` into a hard
    /// cap on peak LR seconds; defaults to 7.5 min/km which is a
    /// reasonable ultra-pace baseline. Pass a faster pace (e.g.
    /// 6.0 min/km) for road athletes when you have one.
    static func from(
        athlete: Athlete,
        ultraFinishCount: Int = 0,
        estimatedLongRunPaceSecondsPerKm: Double = 450 // 7:30 min/km
    ) -> PersonalizationProfile {
        let tenure = tenureMultiplier(years: athlete.runningYears)
        let weight = weightMultiplier(weightKg: athlete.weightKg)
        let ultra = ultraExperienceMultiplier(count: ultraFinishCount)

        let cap: TimeInterval?
        if athlete.longestRunKm > 0 {
            // Allow 20% above what they've demonstrated. This is the
            // "stretch but don't fabricate" bound from coaching practice.
            cap = athlete.longestRunKm * 1.20 * estimatedLongRunPaceSecondsPerKm
        } else {
            cap = nil
        }

        return PersonalizationProfile(
            tenureMultiplier: tenure,
            weightMultiplier: weight,
            ultraExperienceMultiplier: ultra,
            historicalLongRunCapSeconds: cap,
            injuryStructures: athlete.injuryStructures
        )
    }

    static func tenureMultiplier(years: Double) -> Double {
        switch years {
        case ..<1:    return 0.92
        case ..<3:    return 0.95
        case ..<7:    return 1.00
        case ..<15:   return 1.05
        default:      return 1.10
        }
    }

    static func weightMultiplier(weightKg: Double) -> Double {
        switch weightKg {
        case ..<70:  return 1.03
        case ..<85:  return 1.00
        default:     return 0.93
        }
    }

    static func ultraExperienceMultiplier(count: Int) -> Double {
        switch count {
        case ..<1:   return 0.95
        case 1...2:  return 1.00
        case 3...4:  return 1.05
        default:     return 1.10
        }
    }
}
