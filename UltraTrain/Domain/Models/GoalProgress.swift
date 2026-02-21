import Foundation

struct GoalProgress: Equatable, Sendable {
    let goal: TrainingGoal
    var actualDistanceKm: Double
    var actualElevationM: Double
    var actualRunCount: Int
    var actualDurationSeconds: TimeInterval

    var distancePercent: Double {
        guard let target = goal.targetDistanceKm, target > 0 else { return 0 }
        return min(actualDistanceKm / target, 1.0)
    }

    var elevationPercent: Double {
        guard let target = goal.targetElevationM, target > 0 else { return 0 }
        return min(actualElevationM / target, 1.0)
    }

    var runCountPercent: Double {
        guard let target = goal.targetRunCount, target > 0 else { return 0 }
        return min(Double(actualRunCount) / Double(target), 1.0)
    }

    var durationPercent: Double {
        guard let target = goal.targetDurationSeconds, target > 0 else { return 0 }
        return min(actualDurationSeconds / target, 1.0)
    }
}
