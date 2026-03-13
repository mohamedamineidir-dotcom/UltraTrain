import Foundation

/// Estimates missing personal bests from known ones and derives
/// key physiological metrics (VO2max, VMA, threshold paces).
///
/// Uses the Riegel formula for race time prediction and
/// the Daniels/Gilbert VO2max estimation from race performance.
enum PerformanceEstimator {

    // MARK: - Public API

    /// Result of performance estimation from one or more known PBs.
    struct DerivedMetrics: Equatable, Sendable {
        /// Estimated VO2max in ml/kg/min.
        let vo2max: Double
        /// Maximal Aerobic Speed in km/h.
        let vmaKmh: Double
        /// Tempo pace (~60 min threshold effort) in seconds/km.
        let thresholdPace60MinPerKm: Double
        /// Threshold pace (~30 min critical speed effort) in seconds/km.
        let thresholdPace30MinPerKm: Double
    }

    /// Predicts missing PB times from known ones using Riegel's formula.
    ///
    /// - Parameter knownPBs: Array of personal bests with non-zero times.
    /// - Returns: A complete array of 4 PBs (5K, 10K, Half, Marathon),
    ///   with estimated times for distances the user didn't enter.
    ///   Original entries are preserved unchanged.
    static func deduceMissingPBs(from knownPBs: [PersonalBest]) -> [PersonalBest] {
        guard let reference = bestReferencePB(from: knownPBs) else {
            return knownPBs
        }

        let allDistances = PersonalBestDistance.allCases
        var result: [PersonalBest] = []

        for distance in allDistances {
            if let existing = knownPBs.first(where: { $0.distance == distance }) {
                result.append(existing)
            } else {
                let predicted = riegelPredict(
                    knownTime: reference.timeSeconds,
                    knownDistanceKm: reference.distance.distanceKm,
                    targetDistanceKm: distance.distanceKm
                )
                result.append(PersonalBest(
                    id: UUID(),
                    distance: distance,
                    timeSeconds: predicted,
                    date: reference.date
                ))
            }
        }

        return result
    }

    /// Calculates VO2max, VMA, and threshold paces from personal bests.
    ///
    /// Uses the most reliable PB (weighted by recency and distance)
    /// to estimate physiological metrics.
    ///
    /// - Parameter personalBests: Array of personal bests (at least 1 required).
    /// - Returns: Derived metrics, or nil if no PBs provided.
    static func deriveMetrics(from personalBests: [PersonalBest]) -> DerivedMetrics? {
        guard let reference = bestReferencePB(from: personalBests) else {
            return nil
        }

        let vo2max = estimateVO2max(
            distanceM: reference.distance.distanceKm * 1000,
            timeMinutes: reference.timeSeconds / 60.0
        )

        let vma = estimateVMA(vo2max: vo2max)

        let threshold60 = thresholdPace(vmaKmh: vma, fraction: 0.85)
        let threshold30 = thresholdPace(vmaKmh: vma, fraction: 0.92)

        return DerivedMetrics(
            vo2max: (vo2max * 10).rounded() / 10,
            vmaKmh: (vma * 10).rounded() / 10,
            thresholdPace60MinPerKm: threshold60.rounded(),
            thresholdPace30MinPerKm: threshold30.rounded()
        )
    }

    // MARK: - PB Age Adjustment

    /// Adjusts old PBs assuming the athlete has made slight progress.
    /// Conservative: 0.5% faster per year of age, capped at 5 years (~2.5% max).
    /// PBs less than 1 year old are returned unchanged.
    static func adjustPBsForTrainingProgress(_ pbs: [PersonalBest]) -> [PersonalBest] {
        pbs.map { pb in
            let daysSince = Date.now.timeIntervalSince(pb.date) / 86400.0
            guard daysSince > 365 else { return pb }

            let yearsAgo = min(daysSince / 365.0, 5.0)
            let improvementFactor = pow(1.005, yearsAgo)
            let adjustedTime = pb.timeSeconds / improvementFactor

            return PersonalBest(
                id: pb.id,
                distance: pb.distance,
                timeSeconds: adjustedTime,
                date: pb.date
            )
        }
    }

    // MARK: - Riegel Formula

    /// Riegel's formula: T2 = T1 × (D2/D1)^1.06
    /// Well-established for predicting road race times across standard distances.
    private static func riegelPredict(
        knownTime: TimeInterval,
        knownDistanceKm: Double,
        targetDistanceKm: Double
    ) -> TimeInterval {
        guard knownDistanceKm > 0, knownTime > 0 else { return 0 }
        let ratio = targetDistanceKm / knownDistanceKm
        return knownTime * pow(ratio, 1.06)
    }

    // MARK: - VO2max Estimation (Daniels/Gilbert)

    /// Estimates VO2max from a race performance using the Daniels/Gilbert model.
    ///
    /// Formula:
    ///   velocity = distance(m) / time(min)
    ///   VO2 = -4.60 + 0.182258 × v + 0.000104 × v²
    ///   %VO2max = 0.8 + 0.1894393 × e^(-0.012778 × t) + 0.2989558 × e^(-0.1932605 × t)
    ///   VO2max = VO2 / %VO2max
    private static func estimateVO2max(distanceM: Double, timeMinutes: Double) -> Double {
        guard distanceM > 0, timeMinutes > 0 else { return 0 }

        let velocity = distanceM / timeMinutes // m/min

        // Oxygen cost at race pace
        let vo2 = -4.60 + 0.182258 * velocity + 0.000104 * velocity * velocity

        // Fraction of VO2max sustained during the race (duration-dependent)
        let fractionVO2max = 0.8
            + 0.1894393 * exp(-0.012778 * timeMinutes)
            + 0.2989558 * exp(-0.1932605 * timeMinutes)

        guard fractionVO2max > 0 else { return 0 }
        return vo2 / fractionVO2max
    }

    // MARK: - VMA (Vitesse Maximale Aérobie)

    /// Estimates VMA (Maximal Aerobic Speed) from VO2max.
    ///
    /// Uses the ACSM running metabolic equation:
    ///   VO2 = 3.5 + 0.2 × speed(m/min)
    ///   At VO2max → speed = (VO2max - 3.5) / 0.2 m/min → convert to km/h
    private static func estimateVMA(vo2max: Double) -> Double {
        guard vo2max > 3.5 else { return 0 }
        let speedMPerMin = (vo2max - 3.5) / 0.2
        return speedMPerMin * 60.0 / 1000.0 // convert m/min to km/h
    }

    // MARK: - Threshold Paces

    /// Calculates pace (sec/km) at a given fraction of VMA.
    ///
    /// - Parameters:
    ///   - vmaKmh: VMA in km/h
    ///   - fraction: Fraction of VMA (e.g. 0.85 for tempo pace, 0.92 for threshold pace)
    /// - Returns: Pace in seconds per km
    private static func thresholdPace(vmaKmh: Double, fraction: Double) -> Double {
        let thresholdSpeed = vmaKmh * fraction // km/h
        guard thresholdSpeed > 0 else { return 0 }
        return 3600.0 / thresholdSpeed // seconds per km
    }

    // MARK: - Reference PB Selection

    /// Picks the best reference PB for extrapolation.
    /// Prefers longer distances (more reliable for ultra predictions)
    /// weighted by recency.
    private static func bestReferencePB(from pbs: [PersonalBest]) -> PersonalBest? {
        guard !pbs.isEmpty else { return nil }
        if pbs.count == 1 { return pbs[0] }

        // Score = recencyWeight × distanceBonus
        // Longer distances get a bonus since they're more predictive for ultras
        return pbs.max { a, b in
            let scoreA = a.recencyWeight() * distanceBonus(a.distance)
            let scoreB = b.recencyWeight() * distanceBonus(b.distance)
            return scoreA < scoreB
        }
    }

    /// Bonus multiplier favoring longer distances for ultra-focused predictions.
    private static func distanceBonus(_ distance: PersonalBestDistance) -> Double {
        switch distance {
        case .fiveK: 0.7
        case .tenK: 0.85
        case .halfMarathon: 1.0
        case .marathon: 1.1
        }
    }
}
