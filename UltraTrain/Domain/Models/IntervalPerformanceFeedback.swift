import Foundation

/// Per-rep performance capture for road intervals and tempo sessions.
///
/// When a road intervals or tempo session is validated, the athlete optionally
/// logs their actual per-rep paces, whether they completed every prescribed
/// rep, and their perceived effort. IR-2 then aggregates these across recent
/// sessions of the same type to decide whether to adjust future target paces.
///
/// We capture three distinct signals — pace, RPE, completion — because no
/// single one is sufficient on its own:
///   • pace alone can't tell us if the athlete pushed past unsustainable cost
///   • RPE alone misses whether the prescription was physiologically met
///   • completion catches the "hanging on the last two reps" case that pace
///     alone would hide when the athlete bails after nailing the early ones
///
/// `targetPacePerKmAtTime` is a SNAPSHOT of the target the athlete saw when
/// this session was prescribed. Refinement logic reads this rather than
/// recomputing from today's fitness, so a slow session two weeks ago is
/// compared to the target that was in effect then, not the adjusted one.
struct IntervalPerformanceFeedback: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var sessionId: UUID

    /// The session type this feedback belongs to. Intervals and tempo feedbacks
    /// drive different pace adjustments (intervalPacePerKm vs thresholdPacePerKm).
    var sessionType: SessionType

    /// The target pace in seconds/km shown to the athlete at the time the
    /// session was prescribed. Snapshotted so later refinement compares
    /// against the historical target, not today's.
    var targetPacePerKmAtTime: Double

    /// Total prescribed work reps (sum of repeatCount across work phases).
    var prescribedRepCount: Int

    /// Per-rep actual paces (seconds/km). Empty when the athlete used the
    /// "hit target consistently" shortcut — in which case refinement treats
    /// the session as on-target across all reps.
    var actualPacesPerKm: [Double]

    /// Whether the athlete completed every prescribed rep. Kept for
    /// backwards compatibility — new code should prefer
    /// `completedRepCount` which is more granular.
    var completedAllReps: Bool

    /// How many work reps the athlete actually finished. Nil when a legacy
    /// record was loaded before this field existed — callers should fall
    /// back to `completedAllReps` in that case (prescribed or 0). A
    /// specific count (e.g. 8 of 10) lets the refinement use case weight
    /// the slow-down signal by how many reps were actually dropped rather
    /// than treating all "didn't finish" cases equally.
    var completedRepCount: Int?

    /// 1-10 perceived effort. Gates the direction of pace adjustment:
    /// fast paces with high RPE do NOT speed the target up (unsustainable
    /// output, not fitness signal); slow paces with high RPE slow it more.
    var perceivedEffort: Int

    var notes: String?
    var createdAt: Date

    // MARK: - Derived metrics

    /// Mean actual pace across reps, or nil when the athlete used the shortcut.
    var meanActualPacePerKm: Double? {
        guard !actualPacesPerKm.isEmpty else { return nil }
        return actualPacesPerKm.reduce(0, +) / Double(actualPacesPerKm.count)
    }

    /// Deviation in seconds/km vs target. Positive = athlete was slower than
    /// target, negative = faster. Nil when the shortcut was used (treat as 0
    /// in refinement logic).
    var meanDeviationSecondsPerKm: Double? {
        guard let mean = meanActualPacePerKm else { return nil }
        return mean - targetPacePerKmAtTime
    }
}
