import Foundation

struct IntervalWorkout: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var descriptionText: String
    var phases: [IntervalPhase]
    var category: WorkoutCategory
    var estimatedDurationSeconds: TimeInterval
    var estimatedDistanceKm: Double
    var isUserCreated: Bool

    var totalWorkDuration: TimeInterval {
        phases.filter { $0.phaseType == .work }.reduce(0) { $0 + $1.totalDuration }
    }

    var totalRecoveryDuration: TimeInterval {
        phases.filter { $0.phaseType == .recovery }.reduce(0) { $0 + $1.totalDuration }
    }

    var intervalCount: Int {
        phases.filter { $0.phaseType == .work }
            .reduce(0) { $0 + $1.repeatCount }
    }

    var workToRestRatio: Double {
        let recovery = totalRecoveryDuration
        guard recovery > 0 else { return 0 }
        return totalWorkDuration / recovery
    }
}
