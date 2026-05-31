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
