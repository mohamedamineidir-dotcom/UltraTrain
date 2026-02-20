import Foundation

enum WeeklyVolumeCalculator {

    static func compute(
        from runs: [CompletedRun],
        plan: TrainingPlan? = nil,
        weekCount: Int = 8
    ) -> [WeeklyVolume] {
        let calendar = Calendar.current
        let now = Date.now
        var volumes: [WeeklyVolume] = []

        for weeksAgo in (0..<weekCount).reversed() {
            let weekStart = calendar.startOfDay(for: now.adding(weeks: -weeksAgo)).startOfWeek
            let weekEnd = weekStart.adding(days: 7)
            let weekRuns = runs.filter { $0.date >= weekStart && $0.date < weekEnd }

            let (plannedDist, plannedElev) = plannedTargets(for: weekStart, plan: plan)

            volumes.append(WeeklyVolume(
                weekStartDate: weekStart,
                distanceKm: weekRuns.reduce(0) { $0 + $1.distanceKm },
                elevationGainM: weekRuns.reduce(0) { $0 + $1.elevationGainM },
                duration: weekRuns.reduce(0) { $0 + $1.duration },
                runCount: weekRuns.count,
                plannedDistanceKm: plannedDist,
                plannedElevationGainM: plannedElev
            ))
        }
        return volumes
    }

    private static func plannedTargets(
        for weekStart: Date,
        plan: TrainingPlan?
    ) -> (Double, Double) {
        guard let plan else { return (0, 0) }
        guard let week = plan.weeks.first(where: {
            weekStart >= $0.startDate.startOfWeek && weekStart < $0.endDate
        }) else { return (0, 0) }
        return (week.targetVolumeKm, week.targetElevationGainM)
    }
}
