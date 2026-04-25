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

        // Taper weeks: use profile directly (discipline-driven, not plan-length-driven)
        // Pfitzinger: 10K=1wk, HM=2wk, Marathon=3wk — fixed per discipline
        let taperWeeks = totalWeeks < 8
            ? min(taperProfile.totalTaperWeeks, 2)
            : min(taperProfile.totalTaperWeeks, totalWeeks - 3) // Leave at least 3 non-taper weeks
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
    /// Research-corrected fractions:
    /// - **10K** (Daniels): Build is critical (VO2max development). Base 25-30%, Build 35%, Peak 30-35%.
    /// - **HM** (Pfitzinger): Threshold-limited. Needs long build. Base 28-35%, Build 35%, Peak 25-32%.
    /// - **Marathon** (Pfitzinger/Canova/Hanson): Modern marathon coaching gives the
    ///   peak (race-specific) phase 32-37% of the plan — Hanson Method is even
    ///   peak-heavier. Long base is still non-negotiable but the previous
    ///   23-28% peak share starved the cumulative-fatigue stimulus that
    ///   distinguishes a real marathon plan from "long runs + tempos".
    ///   New target: peak 32-37%, build 30-35%, base 28-38%.
    private static func fractions(
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel
    ) -> Fractions {
        switch (discipline, experience) {
        // 10K: speed-centric. Shorter base, heavy build (VO2max), moderate peak.
        // Daniels: Base 27%, Quality 40%, Specific 20%
        case (.road10K, .beginner):     return Fractions(base: 0.30, build: 0.35, peak: 0.35)
        case (.road10K, .intermediate): return Fractions(base: 0.27, build: 0.35, peak: 0.38)
        case (.road10K, .advanced):     return Fractions(base: 0.25, build: 0.35, peak: 0.40)
        case (.road10K, .elite):        return Fractions(base: 0.22, build: 0.35, peak: 0.43)

        // HM: threshold-centric. Pfitzinger: "LT is the HM limiter."
        // Pfitzinger 18/55: Base 33%, Build 33%, Peak 16%. Peak must be SHORT.
        case (.roadHalf, .beginner):     return Fractions(base: 0.38, build: 0.38, peak: 0.24)
        case (.roadHalf, .intermediate): return Fractions(base: 0.35, build: 0.40, peak: 0.25)
        case (.roadHalf, .advanced):     return Fractions(base: 0.32, build: 0.40, peak: 0.28)
        case (.roadHalf, .elite):        return Fractions(base: 0.28, build: 0.42, peak: 0.30)

        // Marathon: aerobic + race-specific. Modern coaching (Hanson, Canova)
        // gives peak 30-37% of plan so cumulative-fatigue stimulus matters.
        // Each row sums to 1.00. Base shrinks as experience rises (assumed
        // pre-existing aerobic foundation), build holds steady, peak grows.
        case (.roadMarathon, .beginner):     return Fractions(base: 0.38, build: 0.30, peak: 0.32)
        case (.roadMarathon, .intermediate): return Fractions(base: 0.35, build: 0.30, peak: 0.35)
        case (.roadMarathon, .advanced):     return Fractions(base: 0.32, build: 0.32, peak: 0.36)
        case (.roadMarathon, .elite):        return Fractions(base: 0.28, build: 0.35, peak: 0.37)
        }
    }

    // RR-8: Removed unused `SubPhase` enum + `subPhase(weekInPhase:)`
    // helper. They were designed to model Pfitzinger/Canova intro/develop/
    // sharpen sub-phases but nothing in the pipeline ever called them.
    // If we add sub-phase-aware logic in the future we'll reintroduce as
    // a dedicated type.
}
