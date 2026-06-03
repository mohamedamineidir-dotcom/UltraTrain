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
        /// The live expected finish (sec).
        let predictedTime: TimeInterval
        /// Signed gap, `predicted - goal` (sec). Positive => the goal is
        /// faster than the prediction (ambitious side).
        let gapSeconds: TimeInterval

        /// A realistic target to one-tap adopt: the expected prediction,
        /// rounded to a clean value so the new goal reads tidily.
        var suggestedTime: TimeInterval {
            (predictedTime / 30.0).rounded() * 30.0
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

    static func assess(goal: RaceGoal, expectedFinish: TimeInterval) -> Assessment? {
        guard case .targetTime(let goalTime) = goal, goalTime > 0, expectedFinish > 0 else {
            return nil
        }
        let gap = expectedFinish - goalTime          // + => goal faster than predicted
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
            gapSeconds: gap
        )
    }
}
