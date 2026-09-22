#if OWNER_MODE
import Foundation

/// Rewrites the pace-derived fields of a structured interval workout's
/// phases after an owner pace edit. Computes duration/distance itself
/// per phase trigger type rather than relying on `IntervalPhase.totalDuration`
/// (which is 0 for `.distance`-triggered phases by design, since the
/// shared model doesn't track a duration for those), so the estimate
/// stays correct for both trigger kinds.
enum OwnerIntervalWorkoutEditor {

    static func apply(_ edits: [OwnerPhasePaceEdit], to workout: IntervalWorkout) -> IntervalWorkout {
        var workout = workout
        var totalDurationSeconds: TimeInterval = 0
        var totalDistanceKm: Double = 0

        for index in workout.phases.indices {
            let phase = workout.phases[index]
            if let edit = edits.first(where: { $0.phaseId == phase.id }), edit.paceSecondsPerKm > 0 {
                workout.phases[index].notes = phaseNotes(for: phase, paceSecondsPerKm: edit.paceSecondsPerKm)
            }
            let contribution = durationAndDistance(
                for: workout.phases[index],
                overridePaceSecondsPerKm: edits.first(where: { $0.phaseId == phase.id })?.paceSecondsPerKm
            )
            totalDurationSeconds += contribution.durationSeconds
            totalDistanceKm += contribution.distanceKm
        }

        workout.estimatedDurationSeconds = totalDurationSeconds
        if totalDistanceKm > 0 {
            workout.estimatedDistanceKm = totalDistanceKm
        }
        return workout
    }

    /// One phase's contribution to the workout's total duration/distance,
    /// given an optional owner-set pace for that phase. Repeat count
    /// applies to both trigger kinds (a "4x" work block repeats its
    /// single-rep duration/distance 4 times).
    private static func durationAndDistance(
        for phase: IntervalPhase,
        overridePaceSecondsPerKm: Double?
    ) -> (durationSeconds: TimeInterval, distanceKm: Double) {
        let reps = Double(max(phase.repeatCount, 1))
        switch phase.trigger {
        case .duration(let seconds):
            let totalSeconds = seconds * reps
            guard let pace = overridePaceSecondsPerKm, pace > 0 else {
                return (totalSeconds, 0)
            }
            return (totalSeconds, totalSeconds / pace)
        case .distance(let km):
            let totalKm = km * reps
            guard let pace = overridePaceSecondsPerKm, pace > 0 else {
                return (0, totalKm)
            }
            return (totalKm * pace, totalKm)
        }
    }

    // Owner-only tooling, not shown to regular users, so this is plain
    // text rather than routed through the localization catalog.
    private static func phaseNotes(for phase: IntervalPhase, paceSecondsPerKm: Double) -> String {
        "Target pace: \(PaceCalculator.formatPace(paceSecondsPerKm))/km"
    }
}
#endif
