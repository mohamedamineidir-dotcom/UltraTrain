import Foundation

enum TrainingCalendarHeatmapCalculator {

    enum IntensityLevel: Int, CaseIterable, Sendable {
        case rest = 0
        case easy = 1
        case moderate = 2
        case hard = 3
        case veryHard = 4
    }

    struct DayIntensity: Identifiable, Equatable, Sendable {
        let id: Date
        var date: Date
        var intensity: IntensityLevel
        var totalDistanceKm: Double
        var totalDuration: TimeInterval
        var runCount: Int
    }

    // MARK: - Public

    static func compute(
        runs: [CompletedRun],
        weeksToShow: Int = 26
    ) -> [DayIntensity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeksToShow * 7

        guard let startDate = calendar.date(byAdding: .day, value: -totalDays + 1, to: today) else {
            return []
        }

        // Index runs by start-of-day
        var runsByDay: [Date: (distanceKm: Double, duration: TimeInterval, count: Int)] = [:]

        for run in runs {
            let dayStart = calendar.startOfDay(for: run.date)

            // Skip runs outside the range
            guard dayStart >= startDate, dayStart <= today else { continue }

            if var existing = runsByDay[dayStart] {
                existing.distanceKm += run.distanceKm
                existing.duration += run.duration
                existing.count += 1
                runsByDay[dayStart] = existing
            } else {
                runsByDay[dayStart] = (
                    distanceKm: run.distanceKm,
                    duration: run.duration,
                    count: 1
                )
            }
        }

        // Build array for every day in range
        var results: [DayIntensity] = []
        results.reserveCapacity(totalDays)

        for dayOffset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }

            if let dayData = runsByDay[date] {
                let intensity = intensityLevel(forDuration: dayData.duration)
                results.append(DayIntensity(
                    id: date,
                    date: date,
                    intensity: intensity,
                    totalDistanceKm: dayData.distanceKm,
                    totalDuration: dayData.duration,
                    runCount: dayData.count
                ))
            } else {
                results.append(DayIntensity(
                    id: date,
                    date: date,
                    intensity: .rest,
                    totalDistanceKm: 0,
                    totalDuration: 0,
                    runCount: 0
                ))
            }
        }

        return results
    }

    // MARK: - Private

    /// Determine intensity based on total training duration for the day.
    /// - rest: 0s (no run)
    /// - easy: up to 45 minutes (2700s)
    /// - moderate: 45 min to 90 min (5400s)
    /// - hard: 90 min to 150 min (9000s)
    /// - veryHard: 150 min and above
    private static func intensityLevel(forDuration duration: TimeInterval) -> IntensityLevel {
        switch duration {
        case ..<1:
            return .rest
        case ..<2700:
            return .easy
        case ..<5400:
            return .moderate
        case ..<9000:
            return .hard
        default:
            return .veryHard
        }
    }
}
