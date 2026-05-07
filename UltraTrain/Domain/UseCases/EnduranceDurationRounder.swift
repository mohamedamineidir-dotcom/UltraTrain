import Foundation

/// Rounds the displayed `plannedDuration` of endurance sessions (long
/// runs, base-endurance / recovery, back-to-back days) to the nearest 5
/// minutes so the schedule reads cleanly — "1h 30min" or "2h 50min"
/// instead of arbitrary "1h 03min" / "2h 48min" values that leak from
/// the underlying floating-point session-budget math.
///
/// Quality work (intervals, tempo, vertical-gain) is left at minute
/// precision because its structure is minute-anchored: a 4×8 min
/// threshold session including warm-up and cool-down doesn't round
/// to a 5-min boundary and rounding the displayed total would imply
/// the workout itself is something other than what it actually is.
///
/// Applied at the session level, AFTER:
/// - SessionTemplateGenerator's effective-duration alignment
/// - The road pipeline's `alignSessionWithWorkout` (which overrides
///   plannedDuration with the workout's actual estimated content)
///
/// so that whatever set the duration last is what gets rounded — there
/// is no upstream mechanism that can un-round the value before the user
/// sees it.
enum EnduranceDurationRounder {

    /// Rounds `plannedDuration` for `.longRun`, `.recovery` (Base
    /// Endurance), and `.backToBack` sessions in-place. Recomputes
    /// `plannedDistanceKm` from the rounded duration so the card's
    /// duration and distance remain consistent.
    static func roundInPlace(_ sessions: inout [TrainingSession]) {
        for i in sessions.indices {
            switch sessions[i].type {
            case .longRun, .recovery, .backToBack:
                let original = sessions[i].plannedDuration
                guard original > 0 else { continue }
                let rounded = (original / 300.0).rounded() * 300.0
                guard rounded != original else { continue }
                let scale = rounded / original
                sessions[i].plannedDuration = rounded
                if sessions[i].plannedDistanceKm > 0 {
                    sessions[i].plannedDistanceKm =
                        (sessions[i].plannedDistanceKm * scale * 10).rounded() / 10
                }
            case .tempo, .intervals, .verticalGain,
                 .crossTraining, .rest, .strengthConditioning, .race:
                continue
            }
        }
    }
}
