import Foundation

struct TaperProfile: Equatable, Sendable {

    enum SubPhase: String, Sendable {
        case volumeTransition
        case trueTaper
    }

    /// Total taper weeks for this race category
    let totalTaperWeeks: Int

    /// Number of initial weeks classified as volume transition (quality sessions present)
    let volumeTransitionWeeks: Int

    /// Volume fraction of peak week per taper week (index 0 = first taper week)
    let weeklyVolumeFractions: [Double]

    /// Whether quality sessions (intervals, VG) are allowed per taper week
    let qualityAllowedPerWeek: [Bool]

    // MARK: - Derived

    func subPhase(forWeekInTaper weekIndex: Int) -> SubPhase {
        weekIndex < volumeTransitionWeeks ? .volumeTransition : .trueTaper
    }

    func volumeFraction(forWeekInTaper weekIndex: Int) -> Double {
        guard weekIndex >= 0, weekIndex < weeklyVolumeFractions.count else {
            return weeklyVolumeFractions.last ?? 0.40
        }
        return weeklyVolumeFractions[weekIndex]
    }

    func isQualityAllowed(forWeekInTaper weekIndex: Int) -> Bool {
        guard weekIndex >= 0, weekIndex < qualityAllowedPerWeek.count else {
            return false
        }
        return qualityAllowedPerWeek[weekIndex]
    }
}

// MARK: - Factory

extension TaperProfile {

    /// Builds a TaperProfile based on race effective distance.
    ///
    /// Categories:
    /// - 100K+ (effectiveKm >= 100): 5 weeks, 2 transition
    /// - 50-99K (50 <= effectiveKm < 100): 4 weeks, 1 transition
    /// - Marathon/Half (21 <= effectiveKm < 50): 2 weeks, no transition
    /// - 10K (effectiveKm < 21): 1 week
    static func forRace(effectiveKm: Double) -> TaperProfile {
        switch effectiveKm {
        case 100...:
            // Sharper drop in the final 2-3 weeks. Old curve [80, 70, 60,
            // 50, 40] was too gradual — modern ultra coaching (Koop, Roche,
            // Krar) cuts more aggressively in the final approach so the
            // athlete arrives genuinely fresh. New curve [80, 65, 50, 40,
            // 30] holds enough first-week volume to stay sharp, then
            // peels harder.
            TaperProfile(
                totalTaperWeeks: 5,
                volumeTransitionWeeks: 2,
                weeklyVolumeFractions: [0.80, 0.65, 0.50, 0.40, 0.30],
                qualityAllowedPerWeek: [true, true, false, false, false]
            )
        case 50..<100:
            // Same principle for 50-99K: tighten the final week.
            TaperProfile(
                totalTaperWeeks: 4,
                volumeTransitionWeeks: 1,
                weeklyVolumeFractions: [0.75, 0.55, 0.40, 0.28],
                qualityAllowedPerWeek: [true, false, false, false]
            )
        case 21..<50:
            TaperProfile(
                totalTaperWeeks: 2,
                volumeTransitionWeeks: 0,
                weeklyVolumeFractions: [0.65, 0.37],
                qualityAllowedPerWeek: [true, false]
            )
        default:
            TaperProfile(
                totalTaperWeeks: 1,
                volumeTransitionWeeks: 0,
                weeklyVolumeFractions: [0.45],
                qualityAllowedPerWeek: [true]
            )
        }
    }

    /// Road race-specific taper profiles.
    ///
    /// Research basis:
    /// - **Mujika & Padilla (2003)**: Optimal taper is 2-3 weeks with 40-60% volume
    ///   reduction but maintained intensity. Performance gains of 2-3%.
    /// - **Daniels**: Quality sessions maintained through taper, volume drops sharply.
    /// - **Pfitzinger**: Marathon taper = 3 weeks (60%→40%→20%). HM = 2 weeks.
    ///   10K = 7-10 days.
    static func forRoadRace(distanceKm: Double) -> TaperProfile {
        let discipline = RoadRaceDiscipline.from(distanceKm: distanceKm)
        switch discipline {
        case .road10K:
            // 10K: 1 week sharp taper. Maintain 1 quality sharpener session.
            // Daniels: keep one set of I-pace intervals 5 days before race.
            return TaperProfile(
                totalTaperWeeks: 1,
                volumeTransitionWeeks: 0,
                weeklyVolumeFractions: [0.65],
                qualityAllowedPerWeek: [true]
            )
        case .roadHalf:
            // Half marathon: 2 weeks. Maintain strides + 1 threshold sharpener.
            // Pfitzinger: 75% → 50%. Keep one quality session per week.
            return TaperProfile(
                totalTaperWeeks: 2,
                volumeTransitionWeeks: 0,
                weeklyVolumeFractions: [0.70, 0.50],
                qualityAllowedPerWeek: [true, true]
            )
        case .roadMarathon:
            // Marathon: 3 weeks. Progressive volume reduction.
            // Pfitzinger: 75% → 55% → 35%. Quality allowed in first 2 weeks.
            return TaperProfile(
                totalTaperWeeks: 3,
                volumeTransitionWeeks: 1,
                weeklyVolumeFractions: [0.75, 0.55, 0.35],
                qualityAllowedPerWeek: [true, true, false]
            )
        }
    }
}
