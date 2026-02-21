import Foundation

struct WeeklyZoneDistributionResult: Equatable, Sendable {
    var weekStartDate: Date
    var distributions: [HeartRateZoneDistribution]
    var totalDurationWithHR: TimeInterval
}

enum WeeklyZoneDistributionCalculator {

    private static let zoneNames = ["Recovery", "Aerobic", "Tempo", "Threshold", "VO2max"]

    static func calculate(
        runs: [CompletedRun],
        weekStartDate: Date,
        maxHeartRate: Int,
        customThresholds: [Int]? = nil
    ) -> WeeklyZoneDistributionResult {
        let weekEnd = weekStartDate.adding(days: 7)
        let weekRuns = runs.filter { $0.date >= weekStartDate && $0.date < weekEnd }

        var zoneDurations: [Int: TimeInterval] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        var totalDuration: TimeInterval = 0

        for run in weekRuns {
            let runDistribution = RunStatisticsCalculator.heartRateZoneDistribution(
                from: run.gpsTrack,
                maxHeartRate: maxHeartRate,
                customThresholds: customThresholds
            )
            for zone in runDistribution {
                zoneDurations[zone.zone, default: 0] += zone.durationSeconds
                totalDuration += zone.durationSeconds
            }
        }

        let distributions = (1...5).map { zone in
            let duration = zoneDurations[zone] ?? 0
            let pct = totalDuration > 0 ? (duration / totalDuration) * 100 : 0
            return HeartRateZoneDistribution(
                zone: zone,
                zoneName: zoneNames[zone - 1],
                durationSeconds: duration,
                percentage: pct
            )
        }

        return WeeklyZoneDistributionResult(
            weekStartDate: weekStartDate,
            distributions: distributions,
            totalDurationWithHR: totalDuration
        )
    }
}
