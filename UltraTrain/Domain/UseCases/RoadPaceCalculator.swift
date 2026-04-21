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
/// - **Pfitzinger**: Easy running should feel truly easy — most runners go too fast.
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
        // Step 1: Determine goal race pace (sec/km)
        let goalPacePerKm: Double
        if let goalTime, goalTime > 0 {
            goalPacePerKm = goalTime / raceDistanceKm
        } else {
            goalPacePerKm = estimatedPace(
                personalBests: personalBests, vmaKmh: vmaKmh,
                targetDistanceKm: raceDistanceKm, experience: experience
            )
        }

        // Step 2: Determine current fitness (estimated 5K pace as anchor)
        var fitness5KPace = estimate5KPace(
            personalBests: personalBests, vmaKmh: vmaKmh, experience: experience
        )

        // Step 2b: If athlete has a goal time, use it to improve 5K estimate
        // Reverse-Riegel: if they believe they can run X marathon, they likely have Y 5K ability.
        // Blend with fitness estimate: realistic goals weight goal-derived 5K more,
        // ambitious goals weight fitness-derived 5K more.
        if let goalTime, goalTime > 0, raceDistanceKm > 10 {
            let goalDerived5KTime = riegelEquivalent(
                fromTime: goalTime, fromDistanceKm: raceDistanceKm, toDistanceKm: 5.0
            )
            let goalDerived5KPace = goalDerived5KTime / 5.0

            // Blend: use the SLOWER of the two estimates (more conservative)
            // but pull toward goal-derived when they're close
            let fitnessDerived = fitness5KPace
            if goalDerived5KPace < fitnessDerived {
                // Goal implies faster 5K than fitness estimate → blend conservatively
                let blendWeight = 0.6 // 60% goal-derived, 40% fitness
                fitness5KPace = goalDerived5KPace * blendWeight + fitnessDerived * (1.0 - blendWeight)
            }
        }

        // Step 3: Goal realism check
        let fitnessPaceAtRaceDist = estimatedPace(
            personalBests: personalBests, vmaKmh: vmaKmh,
            targetDistanceKm: raceDistanceKm, experience: experience
        )
        let realism = goalRealism(goalPace: goalPacePerKm, fitnessPace: fitnessPaceAtRaceDist)

        // Step 4: Derive all training paces from 5K pace using Daniels ratios
        // Validated against Daniels VDOT tables (VDOT 40-65 range).
        //
        // Daniels ratios (5K pace as 1.00):
        // Easy:       1.30 - 1.50× slower (conversational)
        // Marathon:    1.12 - 1.18× slower
        // Threshold:   1.06 - 1.09× slower (~60min race effort)
        // Interval:    1.00× (= 5K pace)
        // Repetition:  0.92 - 0.95× faster (mile pace)
        let fiveK = fitness5KPace

        return RoadPaceProfile(
            easyPacePerKm: (fiveK * 1.30)...(fiveK * 1.48),
            marathonPacePerKm: fiveK * 1.12,
            thresholdPacePerKm: fiveK * 1.09,
            intervalPacePerKm: fiveK * 1.00,
            repetitionPacePerKm: fiveK * 0.93,
            racePacePerKm: goalPacePerKm,
            goalRealismLevel: realism
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
        // Priority 1: Direct 5K PR
        if let fiveKPB = personalBests.first(where: { $0.distance == .fiveK && $0.timeSeconds > 0 }) {
            let decayedTime = fiveKPB.timeSeconds / max(fiveKPB.recencyWeight(), 0.85)
            return decayedTime / 5.0
        }

        // Priority 2: Riegel conversion from nearest PR
        if let bestPB = bestMatchingPR(personalBests: personalBests, targetDistanceKm: 5.0) {
            let equivalent5KTime = riegelEquivalent(
                fromTime: bestPB.timeSeconds,
                fromDistanceKm: bestPB.distance.distanceKm,
                toDistanceKm: 5.0
            )
            let decayedTime = equivalent5KTime / max(bestPB.recencyWeight(), 0.85)
            return decayedTime / 5.0
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
        switch speedImprovement {
        case ..<0.10:  return .realistic      // Goal within 10% of current fitness
        case ..<0.20:  return .ambitious       // 10-20% faster than fitness
        default:       return .veryAmbitious   // >20% faster — flag in advice
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
