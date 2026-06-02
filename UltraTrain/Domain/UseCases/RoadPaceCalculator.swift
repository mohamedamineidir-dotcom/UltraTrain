import Foundation

/// Derives road training pace zones from athlete data.
///
/// **Method**: Estimate equivalent 5K time → derive all paces as ratios of 5K pace.
/// This is more reliable than crude VO2max fraction estimates because the Daniels
/// pace ratios from 5K are well-validated across thousands of athletes.
///
/// Research basis:
/// - **Daniels (2014)**: VDOT tables. All training paces derive from race equivalents.
///   Validated ratios: Easy ≈ 130-150% of 5K pace, Threshold ≈ 106-108% of 5K pace,
///   Interval ≈ 100% of 5K pace, Repetition ≈ 92-95% of 5K pace.
/// - **Riegel (1981)**: T2 = T1 × (D2/D1)^1.06. Adjusted for marathon (1.07).
/// - **Pfitzinger**: Easy running should feel truly easy, most runners go too fast.
///   Easy pace should allow full conversation without breathlessness.
/// - **Jack Daniels VDOT verified data points**:
///   VDOT 40 (4:30 marathon): Easy 6:40-7:24, T 5:36, I 5:08, R 4:48/km
///   VDOT 50 (3:20 marathon): Easy 5:27-6:02, T 4:37, I 4:14, R 3:57/km
///   VDOT 55 (3:00 marathon): Easy 5:06-5:38, T 4:19, I 3:56, R 3:41/km
///   VDOT 60 (2:42 marathon): Easy 4:47-5:16, T 4:03, I 3:41, R 3:27/km
///   VDOT 65 (2:27 marathon): Easy 4:30-4:57, T 3:49, I 3:28, R 3:14/km
enum RoadPaceCalculator {

    // MARK: - Public

    static func paceProfile(
        goalTime: TimeInterval?,
        raceDistanceKm: Double,
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        experience: ExperienceLevel
    ) -> RoadPaceProfile {
        // B1: paces are data-derived when the athlete has at least one PR
        // or a measured VMA. A declared goal time alone is an aspiration,
        // not fitness data, training paces must reflect what the athlete
        // can run today, not what they hope to run on race day. UI falls
        // back to effort/RPE labels when no fitness signal exists, which
        // doubles as the nudge to log a PR.
        let hasAnyPR = personalBests.contains { $0.timeSeconds > 0 }
        let hasVMA = (vmaKmh ?? 0) > 0
        let isDataDerived = hasAnyPR || hasVMA

        // Goal race pace (sec/km). Kept for goalRealism + recommendedGoalTime
        // only, NEVER used to anchor training paces. Falls back to a fitness-
        // derived estimate when the athlete hasn't declared a goal time so
        // the realism scoring still has something to compare against.
        let goalPacePerKm: Double
        if let goalTime, goalTime > 0 {
            goalPacePerKm = goalTime / raceDistanceKm
        } else {
            goalPacePerKm = estimatedPace(
                personalBests: personalBests, vmaKmh: vmaKmh,
                targetDistanceKm: raceDistanceKm, experience: experience
            )
        }

        // Current fitness anchor (estimated 5K pace). Pure fitness-derived,
        // no goal blending: prescribing training paces against the athlete's
        // aspiration asks the body to run intensities it hasn't earned, and
        // erodes the calibration that the rest of the plan relies on.
        let fitness5KPace = estimate5KPace(
            personalBests: personalBests, vmaKmh: vmaKmh, experience: experience
        )

        // Step 3: Goal realism check
        let fitnessPaceAtRaceDist = estimatedPace(
            personalBests: personalBests, vmaKmh: vmaKmh,
            targetDistanceKm: raceDistanceKm, experience: experience
        )
        let realism = goalRealism(goalPace: goalPacePerKm, fitnessPace: fitnessPaceAtRaceDist)

        // RR-19: surface a coach-recommended realistic target time based
        // on the athlete's current fitness. Used by coach advice when the
        // declared goal is flagged .veryAmbitious so the athlete gets a
        // concrete alternative instead of just a warning.
        // Only populated when we have fitness signal AND the profile is
        // genuinely data-derived, we won't fabricate a "realistic" time
        // from the same tier heuristic we just distrusted.
        let recommendedGoalTime: TimeInterval?
        if isDataDerived && fitnessPaceAtRaceDist > 0 {
            recommendedGoalTime = fitnessPaceAtRaceDist * raceDistanceKm
        } else {
            recommendedGoalTime = nil
        }

        // Step 4: Derive all training paces from 5K pace using Daniels ratios
        // Validated against Daniels VDOT tables (VDOT 40-65 range).
        //
        // Daniels ratios (5K pace as 1.00):
        // Easy:       1.30 - 1.42× slower (conversational; tightened from
        //              1.30 - 1.48× because a 50 sec/km E-pace window
        //              stops feeling prescriptive, athletes drift into
        //              zone-3 "moderate" without realising)
        // Marathon:    1.12 - 1.18× slower
        // Threshold:   1.06 - 1.09× slower (~60min race effort)
        // Interval:    1.00× (= 5K pace)
        // Repetition:  0.92 - 0.95× faster (mile pace)
        let fiveK = fitness5KPace

        return RoadPaceProfile(
            easyPacePerKm: (fiveK * 1.30)...(fiveK * 1.42),
            marathonPacePerKm: fiveK * 1.12,
            thresholdPacePerKm: fiveK * 1.09,
            // Daniels T-pace range: 1.06× (cruise intervals, short
            // hard reps) to 1.09× (sustained 30-min tempo). Single
            // value at 1.09 sat at the slower edge, sessions like
            // 4×5min cruise intervals deserve the faster end.
            thresholdPaceRangePerKm: (fiveK * 1.06)...(fiveK * 1.09),
            intervalPacePerKm: fiveK * 1.00,
            repetitionPacePerKm: fiveK * 0.93,
            // Race pace = fitness-derived expected pace at the race distance.
            // The athlete's declared goal still lives in goalRealismLevel +
            // recommendedGoalTime so the UI can surface the gap; training
            // happens at paces the athlete can actually hold today.
            racePacePerKm: fitnessPaceAtRaceDist,
            goalRealismLevel: realism,
            isDataDerived: isDataDerived,
            recommendedGoalTime: recommendedGoalTime
        )
    }

    // MARK: - 5K Pace Estimation (Core Anchor)

    /// Estimates the athlete's current 5K pace from the best available data.
    /// This is the anchor for ALL other pace calculations.
    private static func estimate5KPace(
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        experience: ExperienceLevel
    ) -> Double {
        // Priority 1: best current-fitness signal across ALL PRs.
        // We DON'T short-circuit on a same-distance PR, an athlete who
        // logs a brilliant 10K but carries a stale, slower-equivalent 5K
        // should see their paces track the 10K, not stay pinned to the
        // 5K. `bestFitness5KTime` picks the fastest recency-decayed
        // Riegel-equivalent, so the strongest recent performance wins and
        // a new PR that beats the current estimate actually moves paces.
        if let best5KTime = bestFitness5KTime(personalBests: personalBests) {
            return best5KTime / 5.0
        }

        // Priority 3: Derive from VMA
        // VMA ≈ vVO2max. 5K pace ≈ vVO2max pace (Daniels: 5K ≈ 97-100% VO2max).
        if let vma = vmaKmh, vma > 0 {
            let vVO2maxPacePerKm = 3600.0 / vma
            return vVO2maxPacePerKm * 1.02 // 5K is ~98% of vVO2max → slightly slower
        }

        // Priority 4: Experience-based fallback
        // Based on typical 5K times by experience level
        return fallback5KPace(experience: experience)
    }

    /// The athlete's best current-fitness 5K-equivalent TIME (seconds),
    /// taken as the fastest recency-decayed Riegel projection across every
    /// road PR. This is the single fitness anchor the training paces and
    /// the "current fitness" projections both hang off, so a new PR at any
    /// distance that beats the current estimate immediately tightens paces
    /// everywhere. Returns nil when the athlete has no road PR.
    ///
    /// For a lone 5K PR this is identical to the old direct-PR path
    /// (Riegel 5K→5K is the time itself), so single-PR and already-
    /// consistent athletes are unaffected; only the case where another
    /// distance is a stronger signal changes.
    static func bestFitness5KTime(
        personalBests: [PersonalBest],
        referenceDate: Date = .now
    ) -> TimeInterval? {
        let candidates = personalBests.filter { $0.timeSeconds > 0 }
        guard !candidates.isEmpty else { return nil }
        return candidates.map { pb in
            let equivalent = riegelEquivalent(
                fromTime: pb.timeSeconds,
                fromDistanceKm: pb.distance.distanceKm,
                toDistanceKm: 5.0
            )
            return equivalent / max(pb.recencyWeight(relativeTo: referenceDate), 0.85)
        }.min()
    }

    // MARK: - Riegel Race Equivalence

    /// Riegel formula: T2 = T1 × (D2/D1)^exponent
    /// Marathon uses 1.07 (Canova fatigue adjustment).
    static func riegelEquivalent(
        fromTime: TimeInterval,
        fromDistanceKm: Double,
        toDistanceKm: Double
    ) -> TimeInterval {
        guard fromDistanceKm > 0, fromTime > 0 else { return 0 }
        let exponent = toDistanceKm > 30 ? 1.07 : 1.06
        return fromTime * pow(toDistanceKm / fromDistanceKm, exponent)
    }

    // MARK: - Goal Realism

    /// Classifies how realistic the athlete's goal is.
    ///
    /// A 3:00 marathon for an intermediate athlete is ambitious but NOT "elite."
    /// Elite marathon times are sub-2:30 (men) / sub-2:50 (women).
    /// This classification only compares goal vs estimated current fitness.
    private static func goalRealism(goalPace: Double, fitnessPace: Double) -> GoalRealism {
        guard fitnessPace > 0, goalPace > 0 else { return .realistic }
        // Positive = goal is faster than current fitness
        let speedImprovement = (fitnessPace - goalPace) / fitnessPace
        // Tightened from 10/20 because 10% faster than current fitness is
        // already a stretch in one cycle for most athletes, calling that
        // "realistic" gave overconfident framing. New bands are calibrated
        // against typical season-over-season improvement curves: ≤8% is
        // achievable with focused prep, 8-15% requires everything to go
        // right, >15% is plausible only for fast-improving newer athletes
        // or true outliers and warrants explicit coach pushback.
        switch speedImprovement {
        case ..<0.08:  return .realistic       // ≤8% faster than current fitness
        case ..<0.15:  return .ambitious        // 8-15% faster
        default:       return .veryAmbitious    // >15% faster, flag in advice
        }
    }

    // MARK: - Estimated Pace at Any Distance

    private static func estimatedPace(
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        targetDistanceKm: Double,
        experience: ExperienceLevel
    ) -> Double {
        if let bestPB = bestMatchingPR(personalBests: personalBests, targetDistanceKm: targetDistanceKm) {
            let equivalentTime = riegelEquivalent(
                fromTime: bestPB.timeSeconds,
                fromDistanceKm: bestPB.distance.distanceKm,
                toDistanceKm: targetDistanceKm
            )
            let decayedTime = equivalentTime / max(bestPB.recencyWeight(), 0.85)
            return decayedTime / targetDistanceKm
        }

        // Derive from 5K estimate
        let fiveKPace = estimate5KPace(personalBests: personalBests, vmaKmh: vmaKmh, experience: experience)
        let fiveKTime = fiveKPace * 5.0
        let equivalentTime = riegelEquivalent(fromTime: fiveKTime, fromDistanceKm: 5.0, toDistanceKm: targetDistanceKm)
        return equivalentTime / targetDistanceKm
    }

    // MARK: - Fallbacks

    /// Experience-based 5K pace fallbacks.
    /// Based on RunRepeat global averages by competitive tier:
    /// - Beginner: ~30-35 min 5K → ~6:00-7:00/km
    /// - Intermediate: ~22-27 min 5K → ~4:24-5:24/km
    /// - Advanced: ~18-21 min 5K → ~3:36-4:12/km
    /// - Elite: ~15-17 min 5K → ~3:00-3:24/km
    private static func fallback5KPace(experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     390  // 6:30/km → ~32:30 5K
        case .intermediate: 300  // 5:00/km → ~25:00 5K
        case .advanced:     240  // 4:00/km → ~20:00 5K
        case .elite:        195  // 3:15/km → ~16:15 5K
        }
    }

    // MARK: - PR Selection

    private static func bestMatchingPR(
        personalBests: [PersonalBest],
        targetDistanceKm: Double
    ) -> PersonalBest? {
        guard !personalBests.isEmpty else { return nil }
        return personalBests
            .filter { $0.timeSeconds > 0 }
            .max { pb1, pb2 in
                prScore(pb1, targetDistanceKm: targetDistanceKm)
                    < prScore(pb2, targetDistanceKm: targetDistanceKm)
            }
    }

    private static func prScore(_ pb: PersonalBest, targetDistanceKm: Double) -> Double {
        let distanceRatio = pb.distance.distanceKm / targetDistanceKm
        let closeness = 1.0 / (1.0 + abs(log2(max(distanceRatio, 0.1))))
        return closeness * pb.recencyWeight()
    }
}
