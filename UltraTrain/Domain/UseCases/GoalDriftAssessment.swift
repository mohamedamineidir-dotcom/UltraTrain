import Foundation

/// Compares an athlete's declared target-time goal against the live finish
/// prediction and classifies how far the goal has drifted from current
/// fitness. Powers the dashboard "goal reality check" flag and the one-tap
/// "adjust my goal" action on the finish-estimation screen.
///
/// Only meaningful for `.targetTime` goals: `finish` and `targetRanking`
/// carry no time to compare against, so `assess` returns nil for them.
enum GoalDriftAssessment {

    /// How the declared goal compares to the predicted (expected) finish.
    enum Level: String, Sendable, Equatable {
        /// Goal is far faster than predicted; out of reach without a big leap.
        case veryAmbitious
        /// Goal is moderately faster than predicted; a genuine stretch.
        case ambitious
        /// Goal sits inside the prediction's normal range. No action needed.
        case onTrack
        /// Goal is moderately slower than predicted; the athlete could push.
        case comfortable
        /// Goal is far slower than predicted; well within reach.
        case wellWithinReach
    }

    struct Assessment: Sendable, Equatable {
        let level: Level
        /// The declared goal time (sec).
        let goalTime: TimeInterval
        /// The live expected finish (sec) — what this athlete could do TODAY.
        /// Kept for display/reference; NOT what the goal is judged against
        /// (see `projectedRaceDayTime`).
        let predictedTime: TimeInterval
        /// The live optimistic finish (sec) — used with `predictedTime` to
        /// project what training between now and race day should realistically
        /// unlock. See `suggestedTime`.
        let optimisticTime: TimeInterval
        /// Signed gap, `projectedRaceDayTime - goal` (sec). Positive => the
        /// goal is faster than what training between now and race day should
        /// realistically produce (ambitious side).
        let gapSeconds: TimeInterval
        /// Weeks between now and race day — feeds the race-day projection's
        /// training-window scaling, see `FinishTimeEstimator.projectedRaceDayEstimate`.
        let weeksToRace: Int
        /// What this athlete should realistically be capable of ON RACE DAY,
        /// after training between now and then — the actual baseline the
        /// goal is judged against. NOT the same as `predictedTime` (today's
        /// snapshot): a goal can look "too ambitious" against today's fitness
        /// while being perfectly realistic (or even unambitious) against
        /// this projection, which is exactly the confusion this type exists
        /// to resolve. See `FinishTimeEstimator.projectedRaceDayEstimate`.
        let projectedRaceDayTime: TimeInterval

        /// A realistic target to one-tap adopt — just `projectedRaceDayTime`
        /// rounded to the nearest 30s. Uses the same race-day projection as
        /// the evolution chart and the onboarding goal hint so all three
        /// stay consistent with each other.
        var suggestedTime: TimeInterval {
            (projectedRaceDayTime / 30.0).rounded() * 30.0
        }

        /// Whether the drift is large enough to push an "adjust goal" prompt.
        /// Moderate drift is flagged but left alone (still within reason).
        var suggestsAdjustment: Bool {
            level == .veryAmbitious || level == .wellWithinReach
        }

        /// Whether to surface the flag at all (anything off "on track").
        var isDrifted: Bool { level != .onTrack }
    }

    /// Drift bands as a fraction of the goal time. Distance-running targets
    /// are typically called within ~1-2%; we treat ±2% as "on track",
    /// ±2-6% as a moderate drift, and beyond 6% as a large drift.
    private static let onTrackBand = 0.02
    private static let largeBand = 0.06

    /// - Parameter intensityMultiplier: how hard this athlete is training
    ///   for this race — see `FinishTimeEstimator.trainingIntensityMultiplier`.
    ///   Defaults to neutral (balanced/1.0) when the caller doesn't have the
    ///   athlete's training philosophy in scope.
    static func assess(
        goal: RaceGoal,
        expectedFinish: TimeInterval,
        optimisticFinish: TimeInterval,
        raceDate: Date = .now,
        intensityMultiplier: Double = 1.0
    ) -> Assessment? {
        guard case .targetTime(let goalTime) = goal, goalTime > 0, expectedFinish > 0 else {
            return nil
        }
        let optimistic = optimisticFinish > 0 ? optimisticFinish : expectedFinish
        let secsToRace = raceDate.timeIntervalSinceNow
        let weeksToRace = secsToRace > 0 ? max(0, Int((secsToRace / 86400 / 7).rounded())) : 0

        // The goal must be judged against what training between now and
        // race day should realistically produce, not today's snapshot —
        // otherwise a goal that's genuinely on track (or even unambitious)
        // relative to race-day potential can look "too ambitious" purely
        // because today's fitness hasn't caught up yet.
        let projectedRaceDay = FinishTimeEstimator.projectedRaceDayEstimate(
            optimisticTime: optimistic,
            expectedTime: expectedFinish,
            weeksToRace: weeksToRace,
            intensityMultiplier: intensityMultiplier
        )

        let gap = projectedRaceDay - goalTime          // + => goal faster than race-day projection
        let fraction = gap / goalTime

        let level: Level
        if fraction > largeBand {
            level = .veryAmbitious
        } else if fraction > onTrackBand {
            level = .ambitious
        } else if fraction < -largeBand {
            level = .wellWithinReach
        } else if fraction < -onTrackBand {
            level = .comfortable
        } else {
            level = .onTrack
        }

        return Assessment(
            level: level,
            goalTime: goalTime,
            predictedTime: expectedFinish,
            optimisticTime: optimistic,
            gapSeconds: gap,
            weeksToRace: weeksToRace,
            projectedRaceDayTime: projectedRaceDay
        )
    }
}
