import Foundation

/// Determines the ratio of vertical gain sessions to flat interval sessions
/// based on race type, athlete preference, training phase, and race profile.
enum QualitySessionRatioResolver {

    struct Ratio: Sendable {
        /// Fraction of quality slots that should be VG (0.0 to 1.0).
        let vgFraction: Double
        /// Fraction of quality slots that should be flat intervals.
        var intervalFraction: Double { 1.0 - vgFraction }
    }

    /// Resolves the VG-to-interval ratio for a given week.
    ///
    /// For trail/ultra: respects athlete intervalFocus with phase modulation.
    /// For road: enforces max 1 VG per 4-week block regardless of preference.
    static func resolve(
        raceType: RaceType,
        intervalFocus: IntervalFocus,
        phase: TrainingPhase,
        weekNumberInPhase: Int,
        raceElevationGainM: Double,
        raceDistanceKm: Double
    ) -> Ratio {
        switch raceType {
        case .road:
            return roadRatio(weekNumberInPhase: weekNumberInPhase)
        case .trail:
            let base = trailRatio(focus: intervalFocus, phase: phase)
            let biased = applyElevationBias(
                ratio: base,
                elevationGainM: raceElevationGainM,
                distanceKm: raceDistanceKm
            )
            return biased
        }
    }

    /// For a week with N quality session slots, returns which should be VG.
    /// Returns true for each slot index that should be VG.
    static func assignSlots(
        ratio: Ratio,
        qualitySlotCount: Int,
        weekNumberInPhase: Int
    ) -> [Bool] {
        guard qualitySlotCount > 0 else { return [] }

        if qualitySlotCount == 1 {
            // Single quality slot: use ratio as probability threshold,
            // alternating by week for determinism
            let isVG = weekNumberInPhase % 2 == 0
                ? ratio.vgFraction >= 0.5
                : ratio.vgFraction > 0.5
            return [isVG]
        }

        // 2 slots: assign based on ratio
        let vgCount = Int((Double(qualitySlotCount) * ratio.vgFraction).rounded())
        let clampedVG = min(vgCount, qualitySlotCount)
        return (0..<qualitySlotCount).map { $0 < clampedVG }
    }

    // MARK: - Trail Ratios

    private static func trailRatio(focus: IntervalFocus, phase: TrainingPhase) -> Ratio {
        switch focus {
        case .uphill:
            switch phase {
            case .base:     return Ratio(vgFraction: 0.70)
            case .build:    return Ratio(vgFraction: 0.75)
            case .peak:     return Ratio(vgFraction: 0.65)
            case .taper:    return Ratio(vgFraction: 0.50)
            case .recovery: return Ratio(vgFraction: 0.50)
            case .race:     return Ratio(vgFraction: 0.50)
            }
        case .speed:
            switch phase {
            case .base:     return Ratio(vgFraction: 0.30)
            case .build:    return Ratio(vgFraction: 0.20)
            case .peak:     return Ratio(vgFraction: 0.15)
            case .taper:    return Ratio(vgFraction: 0.20)
            case .recovery: return Ratio(vgFraction: 0.30)
            case .race:     return Ratio(vgFraction: 0.20)
            }
        case .mixed:
            return Ratio(vgFraction: 0.50)
        }
    }

    // MARK: - Road Ratio

    /// Road races: max 1 VG session per 4-week block.
    private static func roadRatio(weekNumberInPhase: Int) -> Ratio {
        let isVGWeek = weekNumberInPhase % 4 == 0
        return Ratio(vgFraction: isVGWeek ? 1.0 : 0.0)
    }

    // MARK: - Elevation Bias

    /// If the race elevation contribution exceeds 30% of effective distance,
    /// nudge +10% VG, capped at 80%.
    private static func applyElevationBias(
        ratio: Ratio,
        elevationGainM: Double,
        distanceKm: Double
    ) -> Ratio {
        guard distanceKm > 0 else { return ratio }

        let elevContributionKm = elevationGainM / 100.0
        let effectiveKm = distanceKm + elevContributionKm
        let elevFraction = elevContributionKm / effectiveKm

        if elevFraction > 0.30 {
            let nudged = min(ratio.vgFraction + 0.10, 0.80)
            return Ratio(vgFraction: nudged)
        }

        return ratio
    }
}
