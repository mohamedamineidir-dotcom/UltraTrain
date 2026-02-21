import Foundation

enum HRVAnalyzer {

    struct HRVTrend: Equatable, Sendable {
        let currentHRV: Double
        let sevenDayAverage: Double
        let thirtyDayAverage: Double
        let trend: TrendDirection
        let percentChangeFromBaseline: Double
        let isSignificantChange: Bool
    }

    enum TrendDirection: String, Sendable {
        case improving
        case stable
        case declining
    }

    static func analyze(readings: [HRVReading]) -> HRVTrend? {
        guard let latest = readings.sorted(by: { $0.date > $1.date }).first else { return nil }
        guard readings.count >= 3 else { return nil }

        let now = Date.now
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        let last7 = readings.filter { $0.date >= sevenDaysAgo }
        let last30 = readings.filter { $0.date >= thirtyDaysAgo }

        let avg7 = last7.isEmpty ? latest.sdnnMs : last7.map(\.sdnnMs).reduce(0, +) / Double(last7.count)
        let avg30 = last30.isEmpty ? latest.sdnnMs : last30.map(\.sdnnMs).reduce(0, +) / Double(last30.count)

        let percentChange = avg30 > 0 ? ((avg7 - avg30) / avg30) * 100 : 0
        let isSignificant = abs(percentChange) > 15

        let trend: TrendDirection
        if percentChange > 5 {
            trend = .improving
        } else if percentChange < -5 {
            trend = .declining
        } else {
            trend = .stable
        }

        return HRVTrend(
            currentHRV: latest.sdnnMs,
            sevenDayAverage: avg7,
            thirtyDayAverage: avg30,
            trend: trend,
            percentChangeFromBaseline: percentChange,
            isSignificantChange: isSignificant
        )
    }

    static func hrvScore(trend: HRVTrend) -> Int {
        // Score based on current HRV relative to personal baseline (30-day avg)
        let ratio = trend.thirtyDayAverage > 0 ? trend.currentHRV / trend.thirtyDayAverage : 1.0

        let baseScore: Double
        if ratio >= 1.1 {
            baseScore = 100
        } else if ratio >= 0.9 {
            // Linear interpolation: 0.9 -> 60, 1.1 -> 100
            baseScore = 60 + (ratio - 0.9) * 200
        } else if ratio >= 0.7 {
            // Linear interpolation: 0.7 -> 20, 0.9 -> 60
            baseScore = 20 + (ratio - 0.7) * 200
        } else {
            baseScore = max(0, ratio * 28.6)
        }

        // Trend bonus/penalty
        let trendAdjustment: Double
        switch trend.trend {
        case .improving: trendAdjustment = 5
        case .stable: trendAdjustment = 0
        case .declining: trendAdjustment = -10
        }

        return max(0, min(100, Int(baseScore + trendAdjustment)))
    }
}
