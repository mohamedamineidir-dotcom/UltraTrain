import Foundation

enum PerformanceTrendAnalyzer {

    struct Input: Sendable {
        let recentRuns: [CompletedRun]
        let restingHeartRates: [(date: Date, bpm: Int)]
    }

    static func analyze(input: Input) -> [PerformanceTrend] {
        var trends: [PerformanceTrend] = []

        let windowDays = AppConfiguration.AICoach.performanceTrendWindowDays
        guard let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -windowDays,
            to: Date.now
        ) else {
            return []
        }

        let filteredRuns = input.recentRuns
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }

        if let trend = analyzeAerobicEfficiency(runs: filteredRuns) {
            trends.append(trend)
        }

        if let trend = analyzeClimbingEfficiency(runs: filteredRuns) {
            trends.append(trend)
        }

        if let trend = analyzeEnduranceFade(runs: filteredRuns) {
            trends.append(trend)
        }

        if let trend = analyzeRecoveryRate(restingHRs: input.restingHeartRates) {
            trends.append(trend)
        }

        return trends
    }

    // MARK: - Aerobic Efficiency

    private static func analyzeAerobicEfficiency(
        runs: [CompletedRun]
    ) -> PerformanceTrend? {
        let moderateRuns = runs.filter { run in
            guard let hr = run.averageHeartRate else { return false }
            return hr >= 130 && hr <= 165 && run.distanceKm >= 3
        }

        guard moderateRuns.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let dataPoints = moderateRuns.map { run in
            TrendDataPoint(
                date: run.date,
                value: 1000.0 / run.averagePaceSecondsPerKm
            )
        }

        let changePercent = percentChange(dataPoints)
        let direction = classifyDirection(changePercent: changePercent)

        let summary: String
        switch direction {
        case .improving:
            summary = "You're getting faster at the same heart rate — aerobic fitness is building."
        case .stable:
            summary = "Aerobic efficiency is steady. Consistent effort is maintaining your fitness."
        case .declining:
            summary = "Pace at moderate effort is slowing. This may indicate accumulated fatigue."
        }

        return PerformanceTrend(
            id: UUID(),
            type: .aerobicEfficiency,
            dataPoints: dataPoints,
            trendDirection: direction,
            changePercent: changePercent,
            summary: summary,
            analyzedDate: Date.now
        )
    }

    // MARK: - Climbing Efficiency

    private static func analyzeClimbingEfficiency(
        runs: [CompletedRun]
    ) -> PerformanceTrend? {
        let hillRuns = runs.filter { $0.elevationGainM > 200 && $0.duration > 0 }

        guard hillRuns.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let dataPoints = hillRuns.map { run in
            TrendDataPoint(
                date: run.date,
                value: run.elevationGainM / (run.duration / 60)
            )
        }

        let changePercent = percentChange(dataPoints)
        let direction = classifyDirection(changePercent: changePercent)

        let summary: String
        switch direction {
        case .improving:
            summary = "Climbing efficiency is improving. You're gaining elevation faster."
        case .stable:
            summary = "Climbing ability is consistent."
        case .declining:
            summary = "Climbing efficiency has dropped. Consider adding specific vertical sessions."
        }

        return PerformanceTrend(
            id: UUID(),
            type: .climbingEfficiency,
            dataPoints: dataPoints,
            trendDirection: direction,
            changePercent: changePercent,
            summary: summary,
            analyzedDate: Date.now
        )
    }

    // MARK: - Endurance Fade

    private static func analyzeEnduranceFade(
        runs: [CompletedRun]
    ) -> PerformanceTrend? {
        let longRuns = runs.filter {
            $0.distanceKm >= AppConfiguration.AICoach.longRunThresholdKm
                && $0.splits.count >= 6
        }

        guard longRuns.count >= 3 else { return nil }

        let dataPoints = longRuns.compactMap { run -> TrendDataPoint? in
            let splits = run.splits.sorted { $0.kilometerNumber < $1.kilometerNumber }
            let thirdSize = max(1, splits.count / 3)

            let firstThird = splits.prefix(thirdSize)
            let lastThird = splits.suffix(thirdSize)

            guard !firstThird.isEmpty, !lastThird.isEmpty else { return nil }

            let firstPace = firstThird.map(\.duration).reduce(0, +)
                / Double(firstThird.count)
            let lastPace = lastThird.map(\.duration).reduce(0, +)
                / Double(lastThird.count)

            guard firstPace > 0 else { return nil }

            let fadePercent = ((lastPace - firstPace) / firstPace) * 100

            return TrendDataPoint(date: run.date, value: fadePercent)
        }

        guard dataPoints.count >= 3 else { return nil }

        let changePercent = percentChange(dataPoints)
        let avgFade = dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)

        // For endurance fade: less fade over time = improving
        let direction: PerformanceTrendDirection
        if changePercent < -2 { direction = .improving }
        else if changePercent > 2 { direction = .declining }
        else { direction = .stable }

        let summary: String
        switch direction {
        case .improving:
            summary = "You're maintaining pace better in the final third of long runs. Endurance is building."
        case .stable:
            summary = "Endurance fade is consistent across recent long runs."
        case .declining:
            summary = "Pace drop-off in late stages of long runs is increasing. Focus on fueling and pacing strategy."
        }

        return PerformanceTrend(
            id: UUID(),
            type: .enduranceFade,
            dataPoints: dataPoints,
            trendDirection: direction,
            changePercent: abs(avgFade),
            summary: summary,
            analyzedDate: Date.now
        )
    }

    // MARK: - Recovery Rate

    private static func analyzeRecoveryRate(
        restingHRs: [(date: Date, bpm: Int)]
    ) -> PerformanceTrend? {
        guard restingHRs.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let sorted = restingHRs.sorted { $0.date < $1.date }

        let dataPoints = sorted.map { entry in
            TrendDataPoint(
                date: entry.date,
                value: Double(entry.bpm)
            )
        }

        let changePercent = percentChange(dataPoints)

        // For resting HR: declining HR = improving recovery
        let direction: PerformanceTrendDirection
        if changePercent < -2 { direction = .improving }
        else if changePercent > 2 { direction = .declining }
        else { direction = .stable }

        let summary: String
        switch direction {
        case .improving:
            summary = "Resting heart rate is trending down — a sign of improving cardiovascular fitness."
        case .stable:
            summary = "Resting heart rate is stable."
        case .declining:
            summary = "Resting heart rate is trending up. This can indicate accumulated fatigue or stress."
        }

        return PerformanceTrend(
            id: UUID(),
            type: .recoveryRate,
            dataPoints: dataPoints,
            trendDirection: direction,
            changePercent: abs(changePercent),
            summary: summary,
            analyzedDate: Date.now
        )
    }

    // MARK: - Math Helpers

    static func linearRegressionSlope(_ points: [TrendDataPoint]) -> Double {
        guard points.count >= 2 else { return 0 }

        let n = Double(points.count)
        let xs = (0..<points.count).map(Double.init)
        let ys = points.map(\.value)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }

    static func percentChange(_ points: [TrendDataPoint]) -> Double {
        guard points.count >= 2 else { return 0 }

        let firstHalf = points.prefix(points.count / 2)
        let secondHalf = points.suffix(points.count - points.count / 2)

        let firstAvg = firstHalf.map(\.value).reduce(0, +)
            / Double(firstHalf.count)
        let secondAvg = secondHalf.map(\.value).reduce(0, +)
            / Double(secondHalf.count)

        guard firstAvg != 0 else { return 0 }
        return ((secondAvg - firstAvg) / abs(firstAvg)) * 100
    }

    // MARK: - Direction Classification

    private static func classifyDirection(
        changePercent: Double
    ) -> PerformanceTrendDirection {
        if abs(changePercent) < 2 { return .stable }
        else if changePercent > 0 { return .improving }
        else { return .declining }
    }
}
