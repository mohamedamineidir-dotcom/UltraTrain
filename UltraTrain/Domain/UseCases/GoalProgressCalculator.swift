import Foundation

enum GoalProgressCalculator {
    static func calculate(goal: TrainingGoal, runs: [CompletedRun]) -> GoalProgress {
        let startOfStartDate = goal.startDate.startOfDay
        let endOfEndDate = Calendar.current.date(byAdding: .day, value: 1, to: goal.endDate.startOfDay) ?? goal.endDate

        let filteredRuns = runs.filter { run in
            run.date >= startOfStartDate && run.date < endOfEndDate
        }

        let totalDistance = filteredRuns.reduce(0) { $0 + $1.distanceKm }
        let totalElevation = filteredRuns.reduce(0) { $0 + $1.elevationGainM }
        let totalDuration = filteredRuns.reduce(0) { $0 + $1.duration }

        return GoalProgress(
            goal: goal,
            actualDistanceKm: totalDistance,
            actualElevationM: totalElevation,
            actualRunCount: filteredRuns.count,
            actualDurationSeconds: totalDuration
        )
    }
}
