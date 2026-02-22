import Foundation

@Observable
@MainActor
final class IntervalWorkoutPreviewViewModel {

    let workout: IntervalWorkout

    init(workout: IntervalWorkout) {
        self.workout = workout
    }

    var flattenedPhases: [(phase: IntervalPhase, repeatIndex: Int)] {
        IntervalGuidanceHandler.flattenPhases(workout.phases)
    }

    var totalPhaseCount: Int { flattenedPhases.count }

    var formattedDuration: String {
        let total = Int(workout.estimatedDurationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    var formattedWorkToRest: String {
        let ratio = workout.workToRestRatio
        guard ratio > 0 else { return "--" }
        return String(format: "%.1f:1", ratio)
    }
}
