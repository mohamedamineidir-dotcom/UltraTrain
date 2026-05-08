import Foundation

/// Decides whether a mid-prep fitness test should be inserted, when,
/// and which variant. The decision factors:
///
/// - Athlete opt-in (sheet at plan-time)
/// - Race profile (skip 100K+ ultras — Koop / House & Johnston explicitly
///   advise against VMA-style tests for ultra athletes)
/// - Plan length (skip plans <8 weeks — not enough plan left to act
///   on the result)
/// - Athlete experience (beginners default OFF; intermediate+ default ON
///   — French school + Roche caveat)
/// - Available terrain (verticalGainEnvironment + uphillDuration drive
///   the trail-test variant; flat-region athletes fall back to VMA flat)
/// - Collisions: ±1 week of any B-race week, the auto Pfitz tune-up,
///   or a periodic fitness check-in.
///
/// Sources:
/// - Pfitzinger *Adv Marathoning* Ch. 5 — tune-up race timing
/// - Daniels *RF* Ch. 5 — VDOT recheck cadence (4-6 weeks)
/// - Magness *Sci of Running* Ch. 11 — field-test cadence
/// - Lacrouts / Cottin / Aubert — VMA test methodology + cadence
/// - Koop *TEU* Ch. 6-7 — explicit warning against VMA tests for ultras
/// - House & Johnston *TUA* Ch. 5 — uphill AnT test + flat-region
///   substitutes (treadmill incline, repeated uphills)
enum FitnessTestScheduler {

    struct Schedule: Equatable, Sendable {
        let weekNumber: Int          // matches WeekSkeleton.weekNumber (1-based)
        let variant: FitnessTestVariant
    }

    /// Plans shorter than this skip the test entirely.
    static let minimumPlanWeeks = 8

    /// Trail / ultra distance threshold above which the test is skipped
    /// entirely — Koop and House & Johnston both argue VMA-style tests
    /// are misleading for ultras (limiter is fueling / durability /
    /// terrain efficiency, not aerobic ceiling).
    static let trailTestSkipThresholdKm: Double = 100

    /// Returns the test schedule, or nil if no test should be inserted.
    static func schedule(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        targetRace: Race,
        athlete: Athlete,
        userOptIn: Bool,
        existingOverrides: [IntermediateRaceHandler.RaceWeekOverride] = [],
        tuneUpWeekNumber: Int? = nil,
        fitnessCheckInWeeks: Set<Int> = []
    ) -> Schedule? {
        guard userOptIn else { return nil }
        guard skeletons.count >= minimumPlanWeeks else { return nil }

        // Skip 100K+ trail / ultra (Koop, House & Johnston).
        if targetRace.raceType == .trail
            && targetRace.distanceKm >= trailTestSkipThresholdKm {
            return nil
        }

        // Pick the candidate week. ≥12-week plans → week 5; 8-12 →
        // week 3. We then look for the closest non-recovery base/build
        // week to the candidate that doesn't collide.
        let totalWeeks = skeletons.count
        let preferredWeekIndex = totalWeeks >= 12 ? 4 : 2  // 0-indexed → week 5 / week 3

        // Search outward from preferredWeekIndex up to ±3 weeks.
        let searchOffsets = [0, 1, -1, 2, -2, 3, -3]
        for offset in searchOffsets {
            let idx = preferredWeekIndex + offset
            guard idx >= 1, idx < totalWeeks else { continue }  // never week 1; never the last week

            let skeleton = skeletons[idx]

            // Phase gates: only base or build, never recovery weeks,
            // never peak/taper/race/post-race.
            guard skeleton.phase == .base || skeleton.phase == .build else { continue }
            guard !skeleton.isRecoveryWeek else { continue }

            // Collision: B-race within ±1 week.
            let bRaceClose = existingOverrides.contains { override in
                override.behavior.isRaceWeek
                    && abs(override.weekNumber - skeleton.weekNumber) <= 1
            }
            if bRaceClose { continue }

            // Collision: auto Pfitz tune-up TT.
            if let tuneUp = tuneUpWeekNumber, abs(tuneUp - skeleton.weekNumber) <= 1 {
                continue
            }

            // Collision: periodic 2K fitness check-in.
            if fitnessCheckInWeeks.contains(skeleton.weekNumber) { continue }

            return Schedule(
                weekNumber: skeleton.weekNumber,
                variant: pickVariant(targetRace: targetRace, athlete: athlete)
            )
        }
        return nil
    }

    /// Selects the test variant by race type + race distance + athlete
    /// terrain access. Public for testability.
    static func pickVariant(
        targetRace: Race,
        athlete: Athlete
    ) -> FitnessTestVariant {
        if targetRace.raceType == .road {
            // Road dispatch: 5K/10K → VMA (race is at/near VMA);
            // HM/Marathon → 5K TT (Daniels VDOT calibration is more
            // relevant for these distances than VMA).
            return targetRace.distanceKm < 15 ? .vmaFlat6Min : .fiveKTT
        }

        // Trail dispatch by terrain access.
        let env = athlete.verticalGainEnvironment
        let uphill = athlete.uphillDuration ?? .none

        if env == .treadmill {
            return .treadmillIncline30Min
        }

        // No usable hills (none / ≤2 min) → 6-min VMA flat test.
        // Calibration is less terrain-specific but still anchors
        // aerobic ceiling. The codebase doesn't have a `.flat` env,
        // so flat-region athletes are typically `.mixed` env with
        // short uphillDuration.
        if uphill == .none || uphill == .upTo2Min {
            return .vmaFlat6Min
        }

        // Athlete has hills. Pick the longest sustained variant they
        // can execute.
        // - .over8Min on mountain terrain: assume long sustained climb
        //   exists → 30-min sustained uphill TT.
        // - .over8Min or .upTo8Min: 4 × 6-8 min repeats.
        // - .upTo4Min or .upTo6Min: 5-6 × 4 min repeats.
        if uphill == .over8Min && env == .mountain {
            return .uphillSustained30Min
        }
        if uphill == .over8Min || uphill == .upTo8Min {
            return .uphillRepeats4x8
        }
        return .uphillRepeats6x4
    }

    /// Smart default for the opt-in toggle in the plan-time onboarding
    /// sheet. The user can always override.
    /// - Beginners default OFF (French school + Roche: too risky)
    /// - 100K+ ultras don't get the question asked
    /// - Plans <8 weeks: not asked (no useful slot for the test)
    /// - Enjoyment philosophy defaults OFF
    /// - Otherwise default ON
    static func defaultOptIn(
        targetRace: Race,
        athlete: Athlete,
        planTotalWeeks: Int
    ) -> Bool {
        if planTotalWeeks < minimumPlanWeeks { return false }
        if targetRace.raceType == .trail
            && targetRace.distanceKm >= trailTestSkipThresholdKm {
            return false
        }
        if athlete.experienceLevel == .beginner { return false }
        if athlete.trainingPhilosophy == .enjoyment { return false }
        return true
    }

    /// Whether the question should even be presented in the plan-time
    /// onboarding sheet.
    static func shouldOfferTest(
        targetRace: Race,
        planTotalWeeks: Int
    ) -> Bool {
        if planTotalWeeks < minimumPlanWeeks { return false }
        if targetRace.raceType == .trail
            && targetRace.distanceKm >= trailTestSkipThresholdKm {
            return false
        }
        return true
    }
}
