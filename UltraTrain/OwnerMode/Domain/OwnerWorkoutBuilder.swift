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
        // Always regenerated from the CURRENT phases, never carried over
        // from the original AI-generated workout — otherwise the
        // description card at the top of the session page keeps
        // describing the pre-edit structure (e.g. "2×10:30...") even
        // after the owner rebuilds the blocks underneath it to something
        // completely different.
        let summary = summaryDescription(for: phases)
        if var workout = existingWorkout {
            workout.phases = phases
            workout.estimatedDurationSeconds = totals.duration
            if totals.distance > 0 {
                workout.estimatedDistanceKm = totals.distance
            }
            workout.descriptionText = summary
            // Also regenerated: the workout NAME (shown right next to
            // "Entraînement"/"Workout" at the top of the card) is just
            // as misleading stale as the description text when it's
            // still the original AI-assigned name for a structure that
            // no longer exists.
            workout.name = "\(sessionType.rawValue.capitalized) (Owner)"
            return workout
        }
        return IntervalWorkout(
            id: UUID(),
            name: "\(sessionType.rawValue.capitalized) (Owner)",
            descriptionText: summary,
            phases: phases,
            category: .trailSpecific,
            estimatedDurationSeconds: totals.duration,
            estimatedDistanceKm: totals.distance,
            isUserCreated: true
        )
    }

    /// Plain-text summary of the phases, grouped the same way
    /// `WorkoutBlocksSection` renders them ("3× 8min at Intense / 2min
    /// recovery"), so the description card at the top of the session
    /// page always matches what's actually below it.
    static func summaryDescription(for phases: [IntervalPhase]) -> String {
        guard !phases.isEmpty else { return "" }
        var parts: [String] = []
        var i = 0
        while i < phases.count {
            let phase = phases[i]
            if phase.phaseType == .work,
               phase.repeatCount > 1,
               i + 1 < phases.count,
               phases[i + 1].phaseType == .recovery {
                let recovery = phases[i + 1]
                parts.append("\(phase.repeatCount)× \(valueText(phase)) at \(phase.targetIntensity.rawValue.capitalized) / \(valueText(recovery)) recovery")
                i += 2
            } else {
                parts.append("\(valueText(phase)) \(phase.phaseType.rawValue)")
                i += 1
            }
        }
        return parts.joined(separator: " + ")
    }

    private static func valueText(_ phase: IntervalPhase) -> String {
        switch phase.trigger {
        case .duration(let seconds):
            let totalSeconds = Int(seconds)
            let minutes = totalSeconds / 60
            let remainderSeconds = totalSeconds % 60
            return remainderSeconds > 0 ? "\(minutes)m\(remainderSeconds)s" : "\(minutes)min"
        case .distance(let km):
            return String(format: "%.1fkm", km)
        }
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
