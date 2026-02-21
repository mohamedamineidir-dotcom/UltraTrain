import Foundation

struct FitnessCalculator: CalculateFitnessUseCase, Sendable {

    // MARK: - Constants

    private static let ctlDays = 42
    private static let atlDays = 7

    // MARK: - Execute

    func execute(
        runs: [CompletedRun],
        asOf date: Date
    ) async throws -> FitnessSnapshot {
        guard !runs.isEmpty else {
            return emptySnapshot(date: date)
        }

        let sortedRuns = runs.sorted { $0.date < $1.date }
        let dailyLoads = buildDailyLoads(from: sortedRuns, upTo: date)
        let ctl = calculateEMA(dailyLoads: dailyLoads, days: Self.ctlDays)
        let atl = calculateEMA(dailyLoads: dailyLoads, days: Self.atlDays)
        let tsb = ctl - atl
        let acr = ctl > 0 ? atl / ctl : 0

        let weeklyStats = calculateWeeklyStats(runs: sortedRuns, asOf: date)
        let monotony = calculateMonotony(dailyLoads: dailyLoads)

        return FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: ctl,
            fatigue: atl,
            form: tsb,
            weeklyVolumeKm: weeklyStats.volumeKm,
            weeklyElevationGainM: weeklyStats.elevationM,
            weeklyDuration: weeklyStats.duration,
            acuteToChronicRatio: acr,
            monotony: monotony
        )
    }

    // MARK: - Training Load

    private func trainingLoad(for run: CompletedRun) -> Double {
        if let tss = run.trainingStressScore { return tss }
        return run.distanceKm + (run.elevationGainM / 100.0)
    }

    // MARK: - Daily Loads

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
                loads[dayIndex] += trainingLoad(for: run)
            }
        }
        return loads
    }

    // MARK: - EMA

    private func calculateEMA(dailyLoads: [Double], days: Int) -> Double {
        guard !dailyLoads.isEmpty else { return 0 }
        let alpha = 2.0 / (Double(days) + 1.0)
        var ema = dailyLoads[0]
        for i in 1..<dailyLoads.count {
            ema = alpha * dailyLoads[i] + (1.0 - alpha) * ema
        }
        return ema
    }

    // MARK: - Weekly Stats

    private func calculateWeeklyStats(
        runs: [CompletedRun],
        asOf date: Date
    ) -> (volumeKm: Double, elevationM: Double, duration: TimeInterval) {
        let sevenDaysAgo = date.adding(days: -7)
        let weekRuns = runs.filter { $0.date >= sevenDaysAgo && $0.date <= date }
        let volume = weekRuns.reduce(0.0) { $0 + $1.distanceKm }
        let elevation = weekRuns.reduce(0.0) { $0 + $1.elevationGainM }
        let duration = weekRuns.reduce(0.0) { $0 + $1.duration }
        return (volume, elevation, duration)
    }

    // MARK: - Monotony

    private func calculateMonotony(dailyLoads: [Double]) -> Double {
        let last7 = Array(dailyLoads.suffix(7))
        guard !last7.isEmpty else { return 0 }

        let mean = last7.reduce(0.0, +) / Double(last7.count)
        guard mean > 0 else { return 0 }

        let variance = last7.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(last7.count)
        let stddev = variance.squareRoot()
        guard stddev > 0 else { return 10.0 } // Perfect monotony: identical daily loads

        return min(mean / stddev, 10.0)
    }

    // MARK: - Empty

    private func emptySnapshot(date: Date) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: 0,
            fatigue: 0,
            form: 0,
            weeklyVolumeKm: 0,
            weeklyElevationGainM: 0,
            weeklyDuration: 0,
            acuteToChronicRatio: 0,
            monotony: 0
        )
    }
}
