import Foundation
import Testing
@testable import UltraTrain

@Suite("PerformanceTrendAnalyzer Tests")
struct PerformanceTrendAnalyzerTests {

    // MARK: - Helpers

    private func makeRun(
        daysAgo: Int,
        pace: Double = 360,
        heartRate: Int? = 145,
        distance: Double = 10,
        elevation: Double = 200,
        duration: TimeInterval = 3600,
        splits: [Split] = []
    ) -> CompletedRun {
        let date = Calendar.current.date(
            byAdding: .day, value: -daysAgo, to: Date.now
        ) ?? Date.distantPast

        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distance,
            elevationGainM: elevation,
            elevationLossM: elevation * 0.8,
            duration: duration,
            averageHeartRate: heartRate,
            maxHeartRate: heartRate.map { $0 + 20 },
            averagePaceSecondsPerKm: pace,
            gpsTrack: [],
            splits: splits,
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeSplit(km: Int, duration: TimeInterval) -> Split {
        Split(
            id: UUID(),
            kilometerNumber: km,
            duration: duration,
            elevationChangeM: 10,
            averageHeartRate: 150
        )
    }

    // MARK: - Tests

    @Test("No data returns empty trends")
    func noData_returnsEmptyTrends() {
        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: [],
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)

        #expect(result.isEmpty)
    }

    @Test("Aerobic efficiency improving when pace increases at moderate HR")
    func aerobicEfficiency_improving() {
        // Need 5+ moderate-HR runs (130-165 bpm) with distance >= 3 km
        // Faster pace (lower s/km) in second half means higher speed = improving
        var runs: [CompletedRun] = []
        // First 3: slower pace at same HR
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 25 - i, pace: 400, heartRate: 150, distance: 8))
        }
        // Last 3: faster pace at same HR
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 5 - i, pace: 350, heartRate: 150, distance: 8))
        }

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: runs,
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let aerobicTrend = result.first { $0.type == .aerobicEfficiency }

        #expect(aerobicTrend != nil)
        #expect(aerobicTrend?.trendDirection == .improving)
        #expect(aerobicTrend?.summary.contains("faster") == true)
    }

    @Test("Climbing efficiency stable when values do not change significantly")
    func climbingEfficiency_stable() {
        // Need 5+ runs with elevation > 200m and duration > 0
        // Similar climbing rates throughout
        var runs: [CompletedRun] = []
        for i in 0..<6 {
            runs.append(makeRun(
                daysAgo: 25 - (i * 4),
                elevation: 400,
                duration: 5400  // 90 min => ~4.4 m/min climbing rate
            ))
        }

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: runs,
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let climbTrend = result.first { $0.type == .climbingEfficiency }

        #expect(climbTrend != nil)
        #expect(climbTrend?.trendDirection == .stable)
    }

    @Test("Endurance fade declining when pace drop-off worsens")
    func enduranceFade_declining() {
        // Need 3+ long runs (>= 15 km) with >= 6 splits each
        // Increasing fade percent over time = declining
        var runs: [CompletedRun] = []

        // Run 1: mild fade (5% slower in last third)
        let splits1 = (1...9).map { km in
            makeSplit(km: km, duration: km <= 3 ? 360 : (km >= 7 ? 378 : 365))
        }
        runs.append(makeRun(daysAgo: 20, distance: 18, duration: 6000, splits: splits1))

        // Run 2: moderate fade (10% slower)
        let splits2 = (1...9).map { km in
            makeSplit(km: km, duration: km <= 3 ? 360 : (km >= 7 ? 396 : 370))
        }
        runs.append(makeRun(daysAgo: 13, distance: 18, duration: 6200, splits: splits2))

        // Run 3: heavy fade (20% slower)
        let splits3 = (1...9).map { km in
            makeSplit(km: km, duration: km <= 3 ? 360 : (km >= 7 ? 432 : 380))
        }
        runs.append(makeRun(daysAgo: 5, distance: 18, duration: 6600, splits: splits3))

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: runs,
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let fadeTrend = result.first { $0.type == .enduranceFade }

        #expect(fadeTrend != nil)
        #expect(fadeTrend?.trendDirection == .declining)
    }

    @Test("Recovery rate improving when resting HR trends downward")
    func recoveryRate_improving() {
        // Need 5+ resting HR readings, declining over time
        let now = Date.now
        let restingHRs: [(date: Date, bpm: Int)] = [
            (Calendar.current.date(byAdding: .day, value: -25, to: now)!, 62),
            (Calendar.current.date(byAdding: .day, value: -20, to: now)!, 61),
            (Calendar.current.date(byAdding: .day, value: -15, to: now)!, 60),
            (Calendar.current.date(byAdding: .day, value: -10, to: now)!, 58),
            (Calendar.current.date(byAdding: .day, value: -5, to: now)!, 56),
            (Calendar.current.date(byAdding: .day, value: -1, to: now)!, 54)
        ]

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: [],
            restingHeartRates: restingHRs
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let recoveryTrend = result.first { $0.type == .recoveryRate }

        #expect(recoveryTrend != nil)
        // Declining resting HR means improving recovery
        #expect(recoveryTrend?.trendDirection == .improving)
        #expect(recoveryTrend?.summary.contains("trending down") == true)
    }

    @Test("Insufficient moderate-HR runs return nil for aerobic efficiency")
    func insufficientModerateRuns_noAerobicTrend() {
        // Only 3 runs (below trendMinDataPoints of 5)
        let runs = (0..<3).map { i in
            makeRun(daysAgo: i * 5, pace: 350, heartRate: 150, distance: 8)
        }

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: runs,
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let aerobicTrend = result.first { $0.type == .aerobicEfficiency }

        #expect(aerobicTrend == nil)
    }

    @Test("Direction classification: < 2% change is stable")
    func directionClassification_thresholds() {
        // Create runs with nearly identical speeds -> stable
        var runs: [CompletedRun] = []
        for i in 0..<6 {
            // Tiny pace variation ~1%
            let pace = 360.0 + (Double(i % 2) * 3.0)
            runs.append(makeRun(daysAgo: 25 - (i * 4), pace: pace, heartRate: 150, distance: 8))
        }

        let input = PerformanceTrendAnalyzer.Input(
            recentRuns: runs,
            restingHeartRates: []
        )

        let result = PerformanceTrendAnalyzer.analyze(input: input)
        let aerobicTrend = result.first { $0.type == .aerobicEfficiency }

        #expect(aerobicTrend != nil)
        #expect(aerobicTrend?.trendDirection == .stable)
    }

    @Test("Linear regression slope computed correctly for known data")
    func linearRegressionSlope_accuracy() {
        // y = 2x + 1: points (0,1), (1,3), (2,5), (3,7)
        let points = [
            TrendDataPoint(date: .now, value: 1),
            TrendDataPoint(date: .now, value: 3),
            TrendDataPoint(date: .now, value: 5),
            TrendDataPoint(date: .now, value: 7)
        ]

        let slope = PerformanceTrendAnalyzer.linearRegressionSlope(points)

        #expect(abs(slope - 2.0) < 0.001)
    }

    @Test("percentChange returns 0 for fewer than 2 data points")
    func percentChange_insufficientData() {
        let single = [TrendDataPoint(date: .now, value: 10)]
        #expect(PerformanceTrendAnalyzer.percentChange(single) == 0)

        let empty: [TrendDataPoint] = []
        #expect(PerformanceTrendAnalyzer.percentChange(empty) == 0)
    }
}
