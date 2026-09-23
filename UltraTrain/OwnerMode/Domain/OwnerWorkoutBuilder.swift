#if OWNER_MODE
import Foundation

/// Builds (or rebuilds) an `IntervalWorkout` from a freeform, owner-
/// edited list of phases — used when the owner replaces a session's
/// blocks wholesale rather than just retuning existing paces (see
/// `OwnerIntervalWorkoutEditor`, which edits pace on a fixed phase
/// list; this builds the phase list itself).
enum OwnerWorkoutBuilder {

    static func build(
        phases: [IntervalPhase],
        existingWorkout: IntervalWorkout?,
        sessionType: SessionType
    ) -> IntervalWorkout {
        let totals = self.totals(for: phases)
        if var workout = existingWorkout {
            workout.phases = phases
            workout.estimatedDurationSeconds = totals.duration
            if totals.distance > 0 {
                workout.estimatedDistanceKm = totals.distance
            }
            return workout
        }
        return IntervalWorkout(
            id: UUID(),
            name: "\(sessionType.rawValue.capitalized) (Owner)",
            descriptionText: "",
            phases: phases,
            category: .trailSpecific,
            estimatedDurationSeconds: totals.duration,
            estimatedDistanceKm: totals.distance,
            isUserCreated: true
        )
    }

    /// Sums duration/distance across phases, repeat count included.
    /// Duration-triggered phases contribute to total duration only;
    /// distance-triggered phases contribute to total distance only
    /// (mirrors `OwnerIntervalWorkoutEditor`'s per-trigger-type math,
    /// since the shared `IntervalPhase.totalDuration` is 0 for
    /// `.distance` triggers by design).
    static func totals(for phases: [IntervalPhase]) -> (duration: TimeInterval, distance: Double) {
        var totalDuration: TimeInterval = 0
        var totalDistance: Double = 0
        for phase in phases {
            let reps = Double(max(phase.repeatCount, 1))
            switch phase.trigger {
            case .duration(let seconds):
                totalDuration += seconds * reps
            case .distance(let km):
                totalDistance += km * reps
            }
        }
        return (totalDuration, totalDistance)
    }
}
#endif
