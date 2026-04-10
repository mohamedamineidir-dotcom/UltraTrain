import Foundation

/// Distributes training phases for road races (10K, Half Marathon, Marathon).
///
/// Research basis:
/// - **Daniels**: Base → quality → specific → taper. Proportions vary by distance.
/// - **Pfitzinger**: Marathon needs longer base (aerobic foundation is king).
///   10K needs more build/peak (speed development). HM is balanced.
/// - **Canova**: General → Fundamental → Special → Specific. Longer specific phase
///   for marathon (4-6 weeks of marathon-pace work before race).
/// - **Lydiard**: Base phase builds the aerobic engine. Quality improves the engine.
///   Peak sharpens for race day. All distances need base, but proportions differ.
///
/// Phase fractions by distance and experience:
/// - Beginners need proportionally more base (less developed aerobic system).
/// - Advanced/elite can handle longer peak phases (higher training tolerance).
/// - Marathon always has proportionally more base than 10K.
enum RoadPhaseDistributor {

    /// Distributes weeks across road-specific training phases.
    /// Returns the same `PhaseAllocation` type as the existing trail PhaseDistributor.
    static func distribute(
        totalWeeks: Int,
        experience: ExperienceLevel,
        raceDistanceKm: Double,
        taperProfile: TaperProfile
    ) -> [PhaseDistributor.PhaseAllocation] {
        guard totalWeeks >= 4 else {
            return [
                PhaseDistributor.PhaseAllocation(phase: .base, weekCount: max(totalWeeks - 1, 1), phaseFocus: .threshold30),
                PhaseDistributor.PhaseAllocation(phase: .taper, weekCount: 1, phaseFocus: .sharpening)
            ]
        }

        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let fracs = fractions(discipline: discipline, experience: experience)

        // Taper weeks from road-specific profile
        let maxTaper = totalWeeks < 8 ? min(taperProfile.totalTaperWeeks, 2) : taperProfile.totalTaperWeeks
        let taperWeeks = min(maxTaper, totalWeeks / 3)
        let remaining = totalWeeks - taperWeeks

        // Distribute remaining across base/build/peak
        let baseWeeks = max(Int(round(Double(remaining) * fracs.base)), 1)
        let buildWeeks = max(Int(round(Double(remaining) * fracs.build)), 1)
        let peakWeeks = max(remaining - baseWeeks - buildWeeks, 1)

        // Road-specific PhaseFocus labels:
        // Base → .threshold30 (aerobic development — same label, different road content)
        // Build → .vo2max (speed/threshold development)
        // Peak → .threshold60 (race-specific preparation)
        // Taper → .sharpening
        return [
            PhaseDistributor.PhaseAllocation(phase: .base, weekCount: baseWeeks, phaseFocus: .threshold30),
            PhaseDistributor.PhaseAllocation(phase: .build, weekCount: buildWeeks, phaseFocus: .vo2max),
            PhaseDistributor.PhaseAllocation(phase: .peak, weekCount: peakWeeks, phaseFocus: .threshold60),
            PhaseDistributor.PhaseAllocation(phase: .taper, weekCount: taperWeeks, phaseFocus: .sharpening),
        ]
    }

    // MARK: - Phase Fractions

    private struct Fractions {
        let base: Double
        let build: Double
        let peak: Double  // Remainder after base + build
    }

    /// Phase fractions by distance and experience.
    ///
    /// 10K: VO2max-heavy build, shorter base. Daniels emphasizes quality over volume.
    /// Half: Balanced. Pfitzinger: threshold development is the cornerstone.
    /// Marathon: Long base phase. Pfitzinger: aerobic foundation before adding specifics.
    private static func fractions(
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel
    ) -> Fractions {
        switch (discipline, experience) {
        // 10K: short base, heavy build+peak for speed development
        case (.road10K, .beginner):     return Fractions(base: 0.30, build: 0.30, peak: 0.40)
        case (.road10K, .intermediate): return Fractions(base: 0.25, build: 0.30, peak: 0.45)
        case (.road10K, .advanced):     return Fractions(base: 0.20, build: 0.30, peak: 0.50)
        case (.road10K, .elite):        return Fractions(base: 0.15, build: 0.25, peak: 0.60)

        // Half marathon: balanced, threshold-heavy
        case (.roadHalf, .beginner):     return Fractions(base: 0.30, build: 0.30, peak: 0.40)
        case (.roadHalf, .intermediate): return Fractions(base: 0.25, build: 0.30, peak: 0.45)
        case (.roadHalf, .advanced):     return Fractions(base: 0.20, build: 0.30, peak: 0.50)
        case (.roadHalf, .elite):        return Fractions(base: 0.15, build: 0.30, peak: 0.55)

        // Marathon: longer base, Pfitzinger-style. Canova: build aerobic engine first.
        case (.roadMarathon, .beginner):     return Fractions(base: 0.35, build: 0.25, peak: 0.40)
        case (.roadMarathon, .intermediate): return Fractions(base: 0.30, build: 0.30, peak: 0.40)
        case (.roadMarathon, .advanced):     return Fractions(base: 0.25, build: 0.30, peak: 0.45)
        case (.roadMarathon, .elite):        return Fractions(base: 0.20, build: 0.30, peak: 0.50)
        }
    }
}
