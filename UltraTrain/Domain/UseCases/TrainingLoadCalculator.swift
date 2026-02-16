import Foundation

struct TrainingLoadCalculator: CalculateTrainingLoadUseCase, Sendable {

    // MARK: - Constants

    private static let historyWeeks = 12
    private static let acrTrendDays = 28
    private static let ctlDays = 42
    private static let atlDays = 7

    // MARK: - Execute

    func execute(
        runs: [CompletedRun],
        plan: TrainingPlan?,
        asOf date: Date
    ) async throws -> TrainingLoadSummary {
        let sortedRuns = runs.sorted { $0.date < $1.date }
        let weeklyHistory = computeWeeklyHistory(runs: sortedRuns, plan: plan, asOf: date)
        let currentWeek = weeklyHistory.last ?? WeeklyLoadData(weekStartDate: date.startOfWeek)
        let acrTrend = computeACRTrend(runs: sortedRuns, asOf: date)
        let monotony = computeMonotony(runs: sortedRuns, asOf: date)

        return TrainingLoadSummary(
            currentWeekLoad: currentWeek,
            weeklyHistory: weeklyHistory,
            acrTrend: acrTrend,
            monotony: monotony,
            monotonyLevel: MonotonyLevel(monotony: monotony)
        )
    }

    // MARK: - Weekly History

    private func computeWeeklyHistory(
        runs: [CompletedRun],
        plan: TrainingPlan?,
        asOf date: Date
    ) -> [WeeklyLoadData] {
        let calendar = Calendar.current
        var history: [WeeklyLoadData] = []

        for weeksAgo in (0..<Self.historyWeeks).reversed() {
            let weekStart = calendar.startOfDay(for: date.adding(weeks: -weeksAgo)).startOfWeek
            let weekEnd = weekStart.adding(days: 7)
            let weekRuns = runs.filter { $0.date >= weekStart && $0.date < weekEnd }

            let actualLoad = weekRuns.reduce(0.0) { $0 + effortLoad(for: $1) }
            let distanceKm = weekRuns.reduce(0.0) { $0 + $1.distanceKm }
            let elevationGainM = weekRuns.reduce(0.0) { $0 + $1.elevationGainM }
            let duration = weekRuns.reduce(0.0) { $0 + $1.duration }
            let plannedLoad = plannedLoadForWeek(weekStart: weekStart, plan: plan)

            history.append(WeeklyLoadData(
                weekStartDate: weekStart,
                actualLoad: actualLoad,
                plannedLoad: plannedLoad,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                duration: duration
            ))
        }

        return history
    }

    private func plannedLoadForWeek(weekStart: Date, plan: TrainingPlan?) -> Double {
        guard let plan else { return 0 }
        guard let week = plan.weeks.first(where: {
            weekStart >= $0.startDate.startOfWeek && weekStart < $0.endDate
        }) else { return 0 }
        return week.targetVolumeKm + (week.targetElevationGainM / 100.0)
    }

    // MARK: - ACR Trend

    private func computeACRTrend(runs: [CompletedRun], asOf date: Date) -> [ACRDataPoint] {
        guard !runs.isEmpty else { return [] }

        let calendar = Calendar.current
        var dataPoints: [ACRDataPoint] = []

        for daysAgo in (0..<Self.acrTrendDays).reversed() {
            let targetDate = calendar.startOfDay(for: date.adding(days: -daysAgo))
            let relevantRuns = runs.filter { $0.date <= targetDate }
            guard !relevantRuns.isEmpty else {
                dataPoints.append(ACRDataPoint(date: targetDate, value: 0))
                continue
            }

            let dailyLoads = buildDailyLoads(from: relevantRuns, upTo: targetDate)
            let ctl = calculateEMA(dailyLoads: dailyLoads, days: Self.ctlDays)
            let atl = calculateEMA(dailyLoads: dailyLoads, days: Self.atlDays)
            let acr = ctl > 0 ? atl / ctl : 0

            dataPoints.append(ACRDataPoint(date: targetDate, value: acr))
        }

        return dataPoints
    }

    // MARK: - Monotony

    private func computeMonotony(runs: [CompletedRun], asOf date: Date) -> Double {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.startOfDay(for: date.adding(days: -6))
        let endDay = calendar.startOfDay(for: date)

        var dailyLoads: [Double] = []
        for dayOffset in 0..<7 {
            let dayStart = sevenDaysAgo.adding(days: dayOffset)
            let dayEnd = dayStart.adding(days: 1)
            let dayRuns = runs.filter { $0.date >= dayStart && $0.date < dayEnd }
            dailyLoads.append(dayRuns.reduce(0.0) { $0 + effortLoad(for: $1) })
        }

        let mean = dailyLoads.reduce(0.0, +) / Double(dailyLoads.count)
        guard mean > 0 else { return 0 }

        let variance = dailyLoads.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(dailyLoads.count)
        let stddev = variance.squareRoot()
        guard stddev > 0 else { return 10.0 } // Perfect monotony: identical daily loads

        return min(mean / stddev, 10.0)
    }

    // MARK: - Helpers

    private func effortLoad(for run: CompletedRun) -> Double {
        run.distanceKm + (run.elevationGainM / 100.0)
    }

    private func buildDailyLoads(from runs: [CompletedRun], upTo endDate: Date) -> [Double] {
        let calendar = Calendar.current
        guard let firstRunDate = runs.first?.date else { return [] }

        let startDay = calendar.startOfDay(for: firstRunDate)
        let endDay = calendar.startOfDay(for: endDate)
        let totalDays = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        guard totalDays >= 0 else { return [] }

        var loads = Array(repeating: 0.0, count: totalDays + 1)
        for run in runs {
            let runDay = calendar.startOfDay(for: run.date)
            let dayIndex = calendar.dateComponents([.day], from: startDay, to: runDay).day ?? 0
            if dayIndex >= 0 && dayIndex < loads.count {
                loads[dayIndex] += effortLoad(for: run)
            }
        }
        return loads
    }

    private func calculateEMA(dailyLoads: [Double], days: Int) -> Double {
        guard !dailyLoads.isEmpty else { return 0 }
        let alpha = 2.0 / (Double(days) + 1.0)
        var ema = dailyLoads[0]
        for i in 1..<dailyLoads.count {
            ema = alpha * dailyLoads[i] + (1.0 - alpha) * ema
        }
        return ema
    }
}
