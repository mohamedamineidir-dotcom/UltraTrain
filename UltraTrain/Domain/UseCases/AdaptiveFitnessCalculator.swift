import Foundation

/// Computes the athlete's adaptive training-fitness anchor: a 5K-equivalent
/// time (seconds) that ratchets faster as sustained training evidence shows
/// improvement, bounded by an experience-scaled ceiling and stepped gently
/// so training paces evolve a few sec/km over a prep rather than jumping.
///
/// Evidence comes from BOTH signals the athlete asked for, each gated by
/// effort so we don't mistake "ran easy days too hard" for fitness:
///  - Easy/long efforts completed faster than baseline at a genuinely easy
///    RPE (completed `TrainingSession` actuals + perceived exertion).
///  - Quality reps run faster than target at a controlled RPE
///    (`IntervalPerformanceFeedback`).
///
/// Stateless target + gradual step from the athlete's stored value, so it
/// can be recomputed on every session completion and converges smoothly.
/// The result floors `RoadPaceCalculator`'s PR/VMA fitness, so easy and
/// quality paces both ease down a little as the athlete trains, without
/// waiting for a freshly logged PR.
enum AdaptiveFitnessCalculator {

    /// Max fractional improvement on the 5K anchor over a full block, by
    /// experience. Calibrated against Daniels VDOT progression, roughly:
    /// beginner ~12-15 s/km easy, intermediate ~8-10, advanced ~5-6, elite
    /// ~2-3. Beginners improve most; elites sit near their ceiling.
    private static func ceilingFraction(_ experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     0.05
        case .intermediate: 0.03
        case .advanced:     0.02
        case .elite:        0.01
        }
    }

    /// New adaptive 5K time, or nil when there's no fitness baseline or no
    /// improvement worth storing (the caller then clears the field and the
    /// athlete falls back to their PR/VMA fitness).
    static func compute(
        athlete: Athlete,
        completedSessions: [TrainingSession],
        intervalFeedback: [IntervalPerformanceFeedback],
        referenceDate: Date = .now
    ) -> TimeInterval? {
        guard let baseline = fitnessBaseline(athlete: athlete) else { return nil }

        // Evidence: 5K-equivalents implied by recent efforts that beat the
        // PR baseline. Require at least two corroborating efforts and take
        // the 2nd-fastest, so a single great day (or a GPS spike) can't pull
        // training paces faster on its own.
        let samples = effortSamples(
            completedSessions: completedSessions,
            intervalFeedback: intervalFeedback,
            referenceDate: referenceDate
        )
        .filter { $0 < baseline }
        .sorted()
        let demonstrated = samples.count >= 2 ? samples[1] : baseline

        // Evolution requires actually training: scale the ceiling by how
        // consistently the athlete is completing sessions lately, so paces
        // only ease down for someone putting in the work.
        let consistency = trainingConsistency(
            athlete: athlete, completedSessions: completedSessions,
            intervalFeedback: intervalFeedback, referenceDate: referenceDate
        )
        let effectiveCeiling = ceilingFraction(athlete.experienceLevel) * consistency
        let floor = baseline * (1.0 - effectiveCeiling)

        // Bounded improvement: as fast as the evidence supports, never below
        // the ceiling, never slower than the PR baseline (the athlete
        // demonstrably has that fitness).
        let evidenceTarget = min(baseline, max(floor, demonstrated))

        // Gradual step toward the target from the current value (both ways,
        // so it relaxes back toward baseline if the athlete detrains),
        // capped per update so a recompute never jumps the prescription.
        let previous = athlete.adaptiveFitness5KSeconds ?? baseline
        let maxStep = baseline * 0.004
        let stepped = previous + clamp(evidenceTarget - previous, -maxStep, maxStep)
        let newAdaptive = min(baseline, max(floor, stepped))

        // Within ~1s of baseline => no meaningful adaptation, clear it.
        return newAdaptive >= baseline - 1 ? nil : newAdaptive
    }

    // MARK: - Evidence

    /// 5K-equivalent times (sec) implied by recent, effort-gated efforts.
    private static func effortSamples(
        completedSessions: [TrainingSession],
        intervalFeedback: [IntervalPerformanceFeedback],
        referenceDate: Date
    ) -> [TimeInterval] {
        let cutoff = referenceDate.addingTimeInterval(-90 * 86400)
        // Midpoint of the easy pace ratio (easyPacePerKm = 1.30...1.42 x 5K
        // pace). Used to map an easy-run pace back to its implied 5K pace.
        let easyRatio = 1.36
        var samples: [TimeInterval] = []

        // Easy efforts: an easy run held FASTER than the pace this fitness
        // would prescribe, at a genuinely easy RPE, means aerobic fitness
        // improved. Comparing to 5K via Riegel would never fire (easy runs
        // sit far below 5K effort), so invert the easy ratio: implied 5K
        // pace = easy pace / 1.36. The RPE<=4 gate is what makes this valid,
        // it filters out "just ran the easy day too hard."
        for session in completedSessions {
            guard session.isCompleted, session.date >= cutoff,
                  session.intensity == .easy,
                  let distanceKm = session.actualDistanceKm,
                  let duration = session.actualDurationSeconds,
                  distanceKm >= 3.0, duration > 0,
                  let rpe = session.perceivedExertion, rpe <= 4 else { continue }
            let effectiveKm = distanceKm + (session.actualElevationGainM ?? 0) / 100.0
            guard effectiveKm >= 3.0 else { continue }
            let easyPace = duration / effectiveKm
            samples.append((easyPace / easyRatio) * 5.0)
        }

        // Quality reps: rep pace at a controlled RPE (fitness headroom, not
        // a maxed-out effort), with the reps actually completed.
        for fb in intervalFeedback {
            guard fb.createdAt >= cutoff,
                  fb.perceivedEffort <= 7,
                  let meanPace = fb.meanActualPacePerKm, meanPace > 0 else { continue }
            let completed = fb.completedRepCount ?? (fb.completedAllReps ? fb.prescribedRepCount : 0)
            guard completed >= fb.prescribedRepCount else { continue }
            // Interval rep pace ~ 5K race pace (Daniels I-pace), so the rep
            // pace is itself a 5K-equivalent pace.
            samples.append(meanPace * 5.0)
        }

        return samples
    }

    // MARK: - Helpers

    private static func fitnessBaseline(athlete: Athlete) -> TimeInterval? {
        if let pr = RoadPaceCalculator.bestFitness5KTime(personalBests: athlete.personalBests) {
            return pr
        }
        if let vma = athlete.vmaKmh, vma > 0 {
            return (3600.0 / vma) * 1.02 * 5.0
        }
        return nil
    }

    /// 0...1 — how close the athlete's recent training activity is to their
    /// preferred cadence over the last three weeks. Counts completed runs
    /// AND logged quality feedback (a quality session that wrote feedback is
    /// activity too), so quality-only evidence still earns an improvement
    /// ceiling. Saturates at 1.0, so any double-count is harmless.
    private static func trainingConsistency(
        athlete: Athlete,
        completedSessions: [TrainingSession],
        intervalFeedback: [IntervalPerformanceFeedback],
        referenceDate: Date
    ) -> Double {
        let cutoff = referenceDate.addingTimeInterval(-21 * 86400)
        let sessionCount = completedSessions.filter {
            $0.isCompleted && $0.date >= cutoff && $0.type != .rest
        }.count
        let feedbackCount = intervalFeedback.filter { $0.createdAt >= cutoff }.count
        let expected = max(1, athlete.preferredRunsPerWeek * 3)
        return min(1.0, Double(sessionCount + feedbackCount) / Double(expected))
    }

    private static func clamp(_ value: Double, _ lo: Double, _ hi: Double) -> Double {
        min(hi, max(lo, value))
    }
}
