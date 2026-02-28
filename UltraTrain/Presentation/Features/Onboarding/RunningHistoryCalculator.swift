import Foundation

enum RunningHistoryCalculator {

    /// Groups workouts by ISO week and returns the mean weekly distance in km.
    static func averageWeeklyKm(from workouts: [HealthKitWorkout]) -> Double {
        var weeklyTotals: [Date: Double] = [:]
        let calendar = Calendar.current
        for workout in workouts where workout.distanceKm > 0 {
            let components = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: workout.startDate
            )
            let weekStart = calendar.date(from: components) ?? workout.startDate
            weeklyTotals[weekStart, default: 0] += workout.distanceKm
        }
        guard !weeklyTotals.isEmpty else { return 0 }
        return weeklyTotals.values.reduce(0, +) / Double(weeklyTotals.count)
    }
}
