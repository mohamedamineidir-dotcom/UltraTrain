#if OWNER_MODE
import Foundation

/// Recomputes a week's target volume/elevation/duration from its
/// sessions' (possibly owner-edited) planned values, so the plan-page
/// charts — which read `TrainingWeek.targetVolumeKm` /
/// `targetElevationGainM` / `targetDurationSeconds` directly rather
/// than summing sessions themselves — reflect an edit immediately.
/// Mirrors `PlanVolumeChartData.extract`'s own active-session filter
/// exactly, so the recomputed target matches what the chart would sum.
enum OwnerWeekAggregateRecalculator {

    static func recalculate(_ week: TrainingWeek) -> TrainingWeek {
        var week = week
        let activeSessions = week.sessions.filter {
            $0.type != .rest && $0.type != .strengthConditioning && !$0.isSkipped
        }
        week.targetVolumeKm = (activeSessions.reduce(0) { $0 + $1.plannedDistanceKm } * 10).rounded() / 10
        week.targetElevationGainM = activeSessions.reduce(0) { $0 + $1.plannedElevationGainM }
        week.targetDurationSeconds = activeSessions.reduce(0) { $0 + $1.plannedDuration }
        return week
    }
}
#endif
