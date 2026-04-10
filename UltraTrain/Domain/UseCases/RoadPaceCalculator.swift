import Foundation

/// Derives road training pace zones from athlete data using Daniels VDOT methodology.
///
/// Research basis:
/// - **Daniels (2014)**: VDOT tables map race performance → training paces.
///   VO2max estimation: VO2max ≈ 0.8 + 0.1894e^(-0.012778*t) + 0.2989e^(-0.1932*t)
///   where t = race time in minutes. Simplified: use pace ratios.
/// - **Riegel (1981)**: Race time prediction: T2 = T1 × (D2/D1)^1.06.
///   Adjusted exponent for marathon (1.07-1.08) per Canova's observation.
/// - **Pfitzinger**: Threshold pace ≈ pace you can sustain for ~60 min all-out.
/// - **Norwegian model**: Sub-threshold training at ~88% of 10K pace.
enum RoadPaceCalculator {

    // MARK: - Public

    /// Computes a complete pace profile for road race training.
    ///
    /// Priority: goalTime > personalBest (with recency decay) > vmaKmh > fallback.
    static func paceProfile(
        goalTime: TimeInterval?,
        raceDistanceKm: Double,
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        experience: ExperienceLevel
    ) -> RoadPaceProfile {
        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)

        // Step 1: Determine goal race pace
        let goalPacePerKm: Double
        if let goalTime, goalTime > 0 {
            goalPacePerKm = goalTime / raceDistanceKm
        } else {
            goalPacePerKm = estimatedPaceFromBestsOrVMA(
                personalBests: personalBests, vmaKmh: vmaKmh,
                targetDistanceKm: raceDistanceKm, experience: experience
            )
        }

        // Step 2: Determine current fitness pace (from best matching PR)
        let fitnessPacePerKm = currentFitnessPace(
            personalBests: personalBests, vmaKmh: vmaKmh,
            targetDistanceKm: raceDistanceKm, experience: experience
        )

        // Step 3: Goal realism check
        let realism = goalRealism(goalPace: goalPacePerKm, fitnessPace: fitnessPacePerKm)

        // Step 4: Derive all training paces from the anchor pace
        // Daniels: training paces are ratios of VO2max velocity
        // We derive from the athlete's estimated VO2max velocity (from best available data)
        let anchorPace = fitnessPacePerKm // Always base training paces on current fitness
        let vVO2max = estimateVVO2maxPacePerKm(from: anchorPace, atDistanceKm: raceDistanceKm)

        return RoadPaceProfile(
            easyPacePerKm: easyRange(vVO2max: vVO2max),
            marathonPacePerKm: vVO2max / 0.80,  // MP ≈ 80% vVO2max
            thresholdPacePerKm: vVO2max / 0.88,  // T ≈ 88% vVO2max
            intervalPacePerKm: vVO2max / 0.98,    // I ≈ 98% vVO2max
            repetitionPacePerKm: vVO2max / 1.05,  // R ≈ 105% vVO2max
            racePacePerKm: goalPacePerKm,
            raceDistanceKm: raceDistanceKm,
            goalRealismLevel: realism
        )
    }

    // MARK: - VO2max Velocity Estimation

    /// Estimates vVO2max pace (sec/km) from a known race pace at a given distance.
    ///
    /// Uses Daniels' fraction of VO2max by race duration:
    /// - 5K (~17-25min): ~95-97% VO2max
    /// - 10K (~35-50min): ~90-93% VO2max
    /// - Half (~75-120min): ~83-88% VO2max
    /// - Marathon (~150-300min): ~75-82% VO2max
    private static func estimateVVO2maxPacePerKm(from pacePerKm: Double, atDistanceKm: Double) -> Double {
        let fractionOfVO2max: Double
        switch atDistanceKm {
        case ..<7:    fractionOfVO2max = 0.96  // ~5K effort
        case ..<15:   fractionOfVO2max = 0.92  // ~10K effort
        case ..<30:   fractionOfVO2max = 0.85  // ~half marathon effort
        default:      fractionOfVO2max = 0.79  // ~marathon effort
        }
        // pace = distance / (time × vVO2max_fraction)
        // vVO2max_pace = pace × fraction (faster pace = lower sec/km)
        return pacePerKm * fractionOfVO2max
    }

    // MARK: - Easy Pace Range

    /// Easy pace range: 65-75% of VO2max velocity (Daniels).
    /// Returns range in sec/km (higher number = slower pace).
    private static func easyRange(vVO2max: Double) -> ClosedRange<Double> {
        let fast = vVO2max / 0.75  // 75% VO2max = faster end of easy
        let slow = vVO2max / 0.65  // 65% VO2max = slower end of easy
        return fast...slow
    }

    // MARK: - Current Fitness Estimation

    /// Estimates current fitness pace at the target distance from PRs or VMA.
    private static func currentFitnessPace(
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        targetDistanceKm: Double,
        experience: ExperienceLevel
    ) -> Double {
        // Find best matching PR (weighted by recency)
        if let bestPB = bestMatchingPR(personalBests: personalBests, targetDistanceKm: targetDistanceKm) {
            let equivalentTime = riegelEquivalent(
                fromTime: bestPB.timeSeconds,
                fromDistanceKm: bestPB.distance.distanceKm,
                toDistanceKm: targetDistanceKm
            )
            // Apply recency decay: PRs older than 12 months are discounted 2-5%
            let weight = bestPB.recencyWeight()
            let decayedTime = equivalentTime / max(weight, 0.80) // Cap decay at 20%
            return decayedTime / targetDistanceKm
        }

        // Fallback: derive from VMA
        if let vma = vmaKmh, vma > 0 {
            return paceFromVMA(vmaKmh: vma, targetDistanceKm: targetDistanceKm)
        }

        // Last resort: experience-based default
        return fallbackPace(experience: experience, distanceKm: targetDistanceKm)
    }

    /// Estimates race pace when no goal time is provided.
    private static func estimatedPaceFromBestsOrVMA(
        personalBests: [PersonalBest],
        vmaKmh: Double?,
        targetDistanceKm: Double,
        experience: ExperienceLevel
    ) -> Double {
        currentFitnessPace(
            personalBests: personalBests, vmaKmh: vmaKmh,
            targetDistanceKm: targetDistanceKm, experience: experience
        )
    }

    // MARK: - Riegel Race Equivalence

    /// Riegel formula: T2 = T1 × (D2/D1)^exponent
    /// Standard exponent: 1.06. Marathon adjusted to 1.07 (Canova).
    static func riegelEquivalent(
        fromTime: TimeInterval,
        fromDistanceKm: Double,
        toDistanceKm: Double
    ) -> TimeInterval {
        guard fromDistanceKm > 0, fromTime > 0 else { return 0 }
        // Marathon+ uses slightly higher exponent (fatigue factor)
        let exponent = toDistanceKm > 30 ? 1.07 : 1.06
        return fromTime * pow(toDistanceKm / fromDistanceKm, exponent)
    }

    // MARK: - Goal Realism

    /// Classifies how realistic the athlete's goal is.
    /// Daniels: don't prescribe paces the athlete can't physiologically sustain.
    private static func goalRealism(goalPace: Double, fitnessPace: Double) -> GoalRealism {
        guard fitnessPace > 0 else { return .realistic }
        let improvement = (fitnessPace - goalPace) / fitnessPace
        switch improvement {
        case ..<0.10:  return .realistic      // ≤10% faster
        case ..<0.25:  return .ambitious       // 10-25% faster
        default:       return .veryAmbitious   // >25% faster
        }
    }

    // MARK: - Fallbacks

    /// Derives pace from VMA (maximal aerobic speed).
    /// vVO2max ≈ VMA, so 10K pace ≈ 92% VMA, HM ≈ 85%, Marathon ≈ 79%.
    private static func paceFromVMA(vmaKmh: Double, targetDistanceKm: Double) -> Double {
        guard vmaKmh > 0 else { return 360 } // 6:00/km fallback
        let vVO2maxPacePerKm = 3600.0 / vmaKmh // sec/km at VMA
        let fraction: Double
        switch targetDistanceKm {
        case ..<7:    fraction = 0.96
        case ..<15:   fraction = 0.92
        case ..<30:   fraction = 0.85
        default:      fraction = 0.79
        }
        return vVO2maxPacePerKm / fraction
    }

    /// Conservative fallback when no fitness data available.
    /// Based on typical recreational runner paces by experience and distance.
    private static func fallbackPace(experience: ExperienceLevel, distanceKm: Double) -> Double {
        let basePace: Double = switch experience {
        case .beginner:     360  // 6:00/km
        case .intermediate: 310  // 5:10/km
        case .advanced:     270  // 4:30/km
        case .elite:        230  // 3:50/km
        }
        // Longer distances = slower pace. ~5% slower per doubling of distance.
        let distanceFactor = 1.0 + 0.05 * log2(max(distanceKm / 10.0, 1.0))
        return basePace * distanceFactor
    }

    // MARK: - PR Selection

    /// Finds the most relevant PR for pace estimation.
    /// Prefers: same distance > nearest distance > any distance.
    /// Weights by recency.
    private static func bestMatchingPR(
        personalBests: [PersonalBest],
        targetDistanceKm: Double
    ) -> PersonalBest? {
        guard !personalBests.isEmpty else { return nil }

        // Score each PR: closeness to target distance × recency weight
        return personalBests
            .filter { $0.timeSeconds > 0 }
            .max { pb1, pb2 in
                let score1 = prScore(pb1, targetDistanceKm: targetDistanceKm)
                let score2 = prScore(pb2, targetDistanceKm: targetDistanceKm)
                return score1 < score2
            }
    }

    private static func prScore(_ pb: PersonalBest, targetDistanceKm: Double) -> Double {
        let distanceRatio = pb.distance.distanceKm / targetDistanceKm
        // Closeness: 1.0 = exact match, 0.5 = 2x or 0.5x different
        let closeness = 1.0 / (1.0 + abs(log2(max(distanceRatio, 0.1))))
        return closeness * pb.recencyWeight()
    }
}
