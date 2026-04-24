import Foundation

/// Selects plan weeks where a periodic fitness check-in (a short 2K
/// time trial) should be inserted to re-anchor pace targets with fresh
/// data. Long training blocks drift — the athlete's fitness quietly
/// improves but the plan's prescribed paces are still derived from
/// whatever baseline existed at plan generation. Without periodic
/// re-anchoring, quality sessions gradually under-prescribe as the
/// athlete gets fitter.
///
/// The tune-up time trial (RR-18) already handles the late-peak case.
/// This fills the earlier block with shorter, more frequent check-ins
/// that don't require as much taper.
///
/// Rules:
///   • Only base + build weeks are eligible. Peak is already
///     race-specific; taper + race are sacred; post-race recovery is
///     not for hard efforts.
///   • Recovery weeks always skipped.
///   • First check-in is the 6th eligible week at the earliest — the
///     athlete needs some training to actually test.
///   • Cadence: every 6 eligible weeks thereafter.
///   • Skip any week within ±1 of an auto-inserted tune-up — two hard
///     tests back-to-back is bad load management.
///   • Plan needs ≥10 eligible base/build weeks total before any
///     check-in runs. Short plans don't have room for a fitness test
///     without compromising the block's build.
enum PlanFitnessCheckIn {

    static let cadence = 6
    static let minimumEligibleWeeks = 10

    /// Returns the set of plan weekNumbers that should host a check-in.
    /// `tuneUpWeekNumber` comes from `computeTuneUpWeekNumber` in the
    /// generator so the two features don't collide.
    static func checkInWeekNumbers(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        tuneUpWeekNumber: Int?
    ) -> Set<Int> {
        let eligible = skeletons.filter { skeleton in
            (skeleton.phase == .base || skeleton.phase == .build)
                && !skeleton.isRecoveryWeek
        }
        guard eligible.count >= minimumEligibleWeeks else { return [] }

        var result: Set<Int> = []
        for (eligibleIndex, skeleton) in eligible.enumerated() {
            let oneBased = eligibleIndex + 1
            // First check-in at week 6, then every `cadence` after.
            guard oneBased >= cadence && oneBased % cadence == 0 else { continue }
            if let tuneUp = tuneUpWeekNumber, abs(skeleton.weekNumber - tuneUp) <= 1 {
                continue
            }
            result.insert(skeleton.weekNumber)
        }
        return result
    }

    /// Description shown on the check-in session card. Kept short —
    /// details go into the coach advice field.
    static let description = """
Fitness check-in: 2 km time trial at max effort.

Warm up 15-20 min easy + 4 strides.
Run 2 km as hard as you sustainably can.
Cool down 10 min.

The result updates the plan's target paces for the next block.
"""

    /// Coach advice for check-in sessions. Frames the session as
    /// information-gathering rather than another interval workout, and
    /// reminds the athlete to enter their time on validate so the
    /// refinement can kick in.
    static let coachAdvice = """
📊 Fitness check-in. This is a test, not a workout. Go all-out over \
2 km — no pacing games. Your time updates the pace targets for the \
next block of training so the prescriptions stay honest to your \
current fitness. Make sure to log your actual pace when you validate.
"""

    static func intervalFocusLabel() -> String { "Check-in" }
}
