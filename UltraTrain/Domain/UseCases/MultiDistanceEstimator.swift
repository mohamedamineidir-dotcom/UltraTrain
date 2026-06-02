import Foundation

/// Projects estimated race times across the four common road distances
/// (5K / 10K / Half / Marathon) from the athlete's current fitness.
///
/// Reuses `RoadPaceCalculator`'s Riegel + 5K-anchor logic so the
/// projections track the same fitness model the training plan uses.
///
/// The output is intentionally simple — one row per distance with a
/// time + per-km pace + an "is this a real PR" flag so the PR page can
/// distinguish recorded PRs from projections derived from them.
enum MultiDistanceEstimator {

    struct Estimate: Equatable, Sendable {
        let distance: PersonalBestDistance
        /// Projected finish time at this distance, derived from current
        /// fitness via Riegel. `nil` when there's no fitness signal at
        /// all (no PRs and no VMA).
        let projectedSeconds: TimeInterval?
        /// Per-km pace implied by the projection.
        let pacePerKm: TimeInterval?
        /// The athlete's recorded PR for this distance, when one exists.
        /// A `nil` PR with a non-nil projection means "we have fitness
        /// data from another distance but no PR at this one yet."
        let recordedPR: PersonalBest?
    }

    /// Computes estimates for all four standard road distances. Estimates
    /// are derived from the athlete's best fitness signal (most-recent
    /// PR with recency weighting, or VMA). When the athlete has no usable
    /// signal, every `projectedSeconds` is `nil` and the UI should prompt
    /// the athlete to log a first PR.
    static func estimates(
        for athlete: Athlete,
        referenceDate: Date = .now
    ) -> [Estimate] {
        PersonalBestDistance.allCases.map { distance in
            let recorded = athlete.personalBests.first {
                $0.distance == distance && $0.timeSeconds > 0
            }
            let projected = projectTime(
                for: distance,
                athlete: athlete,
                referenceDate: referenceDate
            )
            let pace: TimeInterval? = projected.map { $0 / distance.distanceKm }
            return Estimate(
                distance: distance,
                projectedSeconds: projected,
                pacePerKm: pace,
                recordedPR: recorded
            )
        }
    }

    /// A single, internally CONSISTENT set of projections across the four
    /// distances, all derived from one fitness anchor (the athlete's best
    /// recency-weighted 5K-equivalent, or VMA as a fallback). Unlike
    /// `estimates`, this never substitutes a same-distance PR, so the
    /// paces are always monotonic (5K faster per km than 10K than Half
    /// than Marathon). This is the "current fitness estimate" the athlete
    /// reads as their equivalence across distances, and it moves whenever
    /// a new PR beats the current anchor.
    ///
    /// Returns nil when there's no fitness signal at all (no PR, no VMA).
    static func fitnessProjections(
        for athlete: Athlete,
        recentRuns: [CompletedRun] = [],
        referenceDate: Date = .now
    ) -> [Estimate]? {
        let anchor5KTime: TimeInterval
        if let best = RoadPaceCalculator.bestFitness5KTime(
            personalBests: athlete.personalBests,
            recentRuns: recentRuns,
            referenceDate: referenceDate
        ) {
            anchor5KTime = best
        } else if let vma = athlete.vmaKmh, vma > 0 {
            anchor5KTime = (3600.0 / vma) * 1.02 * 5.0
        } else {
            return nil
        }

        return PersonalBestDistance.allCases.map { distance in
            let time = distance == .fiveK
                ? anchor5KTime
                : RoadPaceCalculator.riegelEquivalent(
                    fromTime: anchor5KTime,
                    fromDistanceKm: 5.0,
                    toDistanceKm: distance.distanceKm
                )
            return Estimate(
                distance: distance,
                projectedSeconds: time,
                pacePerKm: time / distance.distanceKm,
                recordedPR: nil
            )
        }
    }

    // MARK: - Projection

    /// Projects a finish time at `distance` from the athlete's fitness.
    /// Priority order matches `RoadPaceCalculator`:
    /// 1. A direct PR at the target distance (use it as-is).
    /// 2. Riegel from the best-matching PR (recency-weighted).
    /// 3. Derive from VMA (5K ≈ 98% vVO2max).
    /// 4. Fall back to nil — the UI prompts for a PR.
    private static func projectTime(
        for distance: PersonalBestDistance,
        athlete: Athlete,
        referenceDate: Date
    ) -> TimeInterval? {
        // 1. Direct PR at the target distance.
        if let direct = athlete.personalBests.first(where: {
            $0.distance == distance && $0.timeSeconds > 0
        }) {
            return direct.timeSeconds
        }

        // 2. Riegel from the best-matching PR.
        let candidates = athlete.personalBests.filter { $0.timeSeconds > 0 }
        if let best = candidates.max(by: { a, b in
            score(a, target: distance, referenceDate: referenceDate)
                < score(b, target: distance, referenceDate: referenceDate)
        }) {
            let equivalent = RoadPaceCalculator.riegelEquivalent(
                fromTime: best.timeSeconds,
                fromDistanceKm: best.distance.distanceKm,
                toDistanceKm: distance.distanceKm
            )
            // Recency-decay the projection: an HM PR from 14 months ago
            // shouldn't project a "current" marathon time as if the
            // athlete were race-fit today.
            let recency = max(best.recencyWeight(relativeTo: referenceDate), 0.85)
            return equivalent / recency
        }

        // 3. Derive from VMA. VMA ≈ vVO2max in km/h. 5K pace ≈ 98% vVO2max
        // → 5K time = (3600 / VMA) × 1.02 × 5. Riegel from there to the
        // target distance.
        if let vma = athlete.vmaKmh, vma > 0 {
            let fiveKPacePerKm = (3600.0 / vma) * 1.02
            let fiveKTime = fiveKPacePerKm * 5.0
            if distance == .fiveK { return fiveKTime }
            return RoadPaceCalculator.riegelEquivalent(
                fromTime: fiveKTime,
                fromDistanceKm: 5.0,
                toDistanceKm: distance.distanceKm
            )
        }

        return nil
    }

    /// Scores a PR's suitability for projecting `target`. Closer
    /// distances (log-scale) and more recent PRs score higher. Mirrors
    /// `RoadPaceCalculator.prScore` so the projector and the calculator
    /// pick the same anchor PR.
    private static func score(
        _ pb: PersonalBest,
        target: PersonalBestDistance,
        referenceDate: Date
    ) -> Double {
        let ratio = pb.distance.distanceKm / target.distanceKm
        let closeness = 1.0 / (1.0 + abs(log2(max(ratio, 0.1))))
        return closeness * pb.recencyWeight(relativeTo: referenceDate)
    }
}
