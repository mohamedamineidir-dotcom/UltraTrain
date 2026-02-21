import Foundation
import Testing
@testable import UltraTrain

@Suite("HRVAnalyzer Tests")
struct HRVAnalyzerTests {

    // MARK: - Helpers

    private func makeReading(daysAgo: Int = 0, sdnnMs: Double = 45.0) -> HRVReading {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return HRVReading(date: date, sdnnMs: sdnnMs)
    }

    // MARK: - analyze() nil cases

    @Test("Empty readings returns nil")
    func analyzeEmptyReadings() {
        let result = HRVAnalyzer.analyze(readings: [])
        #expect(result == nil)
    }

    @Test("Single reading returns nil — fewer than 3 needed")
    func analyzeSingleReading() {
        let readings = [makeReading(daysAgo: 0, sdnnMs: 50)]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result == nil)
    }

    @Test("Two readings returns nil — fewer than 3 needed")
    func analyzeTwoReadings() {
        let readings = [
            makeReading(daysAgo: 0, sdnnMs: 50),
            makeReading(daysAgo: 1, sdnnMs: 48)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result == nil)
    }

    // MARK: - analyze() valid cases

    @Test("Three recent readings returns non-nil trend with correct currentHRV")
    func analyzeThreeRecentReadings() {
        let readings = [
            makeReading(daysAgo: 0, sdnnMs: 55),
            makeReading(daysAgo: 2, sdnnMs: 50),
            makeReading(daysAgo: 4, sdnnMs: 45)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result != nil)
        #expect(result?.currentHRV == 55)
    }

    @Test("Improving trend when 7-day avg is significantly higher than 30-day avg")
    func analyzeImprovingTrend() {
        // Older readings (15-25 days ago) with low SDNN
        // Recent readings (1-5 days ago) with high SDNN
        let readings = [
            makeReading(daysAgo: 1, sdnnMs: 50),
            makeReading(daysAgo: 3, sdnnMs: 50),
            makeReading(daysAgo: 5, sdnnMs: 50),
            makeReading(daysAgo: 15, sdnnMs: 30),
            makeReading(daysAgo: 18, sdnnMs: 30),
            makeReading(daysAgo: 20, sdnnMs: 30),
            makeReading(daysAgo: 25, sdnnMs: 30)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result != nil)
        #expect(result?.trend == .improving)
    }

    @Test("Declining trend when 7-day avg is significantly lower than 30-day avg")
    func analyzeDecliningTrend() {
        // Older readings with high SDNN, recent with low SDNN
        let readings = [
            makeReading(daysAgo: 1, sdnnMs: 25),
            makeReading(daysAgo: 3, sdnnMs: 25),
            makeReading(daysAgo: 5, sdnnMs: 25),
            makeReading(daysAgo: 15, sdnnMs: 55),
            makeReading(daysAgo: 18, sdnnMs: 55),
            makeReading(daysAgo: 20, sdnnMs: 55),
            makeReading(daysAgo: 25, sdnnMs: 55)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result != nil)
        #expect(result?.trend == .declining)
    }

    @Test("Stable trend when 7-day avg is within 5% of 30-day avg")
    func analyzeStableTrend() {
        // All readings at very similar values so 7-day and 30-day averages are close
        let readings = [
            makeReading(daysAgo: 1, sdnnMs: 45),
            makeReading(daysAgo: 3, sdnnMs: 46),
            makeReading(daysAgo: 5, sdnnMs: 44),
            makeReading(daysAgo: 15, sdnnMs: 45),
            makeReading(daysAgo: 18, sdnnMs: 44),
            makeReading(daysAgo: 20, sdnnMs: 46),
            makeReading(daysAgo: 25, sdnnMs: 45)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result != nil)
        #expect(result?.trend == .stable)
    }

    @Test("Significant change detected when percent change exceeds 15%")
    func analyzeSignificantChange() {
        // Recent readings much higher than old ones — >15% change
        let readings = [
            makeReading(daysAgo: 1, sdnnMs: 60),
            makeReading(daysAgo: 3, sdnnMs: 60),
            makeReading(daysAgo: 5, sdnnMs: 60),
            makeReading(daysAgo: 15, sdnnMs: 30),
            makeReading(daysAgo: 18, sdnnMs: 30),
            makeReading(daysAgo: 20, sdnnMs: 30),
            makeReading(daysAgo: 25, sdnnMs: 30)
        ]
        let result = HRVAnalyzer.analyze(readings: readings)
        #expect(result != nil)
        #expect(result?.isSignificantChange == true)
    }

    // MARK: - hrvScore()

    @Test("HRV score near 100 when ratio >= 1.1 and improving trend")
    func hrvScoreHighRatioImproving() {
        let trend = HRVAnalyzer.HRVTrend(
            currentHRV: 66,
            sevenDayAverage: 60,
            thirtyDayAverage: 50,
            trend: .improving,
            percentChangeFromBaseline: 20,
            isSignificantChange: true
        )
        // ratio = 66 / 50 = 1.32 (>= 1.1), so baseScore = 100, +5 for improving = 105 clamped to 100
        let score = HRVAnalyzer.hrvScore(trend: trend)
        #expect(score == 100)
    }

    @Test("HRV score between 60 and 100 when ratio is 0.9 to 1.1 and stable trend")
    func hrvScoreMidRangeStable() {
        let trend = HRVAnalyzer.HRVTrend(
            currentHRV: 50,
            sevenDayAverage: 50,
            thirtyDayAverage: 50,
            trend: .stable,
            percentChangeFromBaseline: 0,
            isSignificantChange: false
        )
        // ratio = 50 / 50 = 1.0, baseScore = 60 + (1.0 - 0.9) * 200 = 80, +0 stable = 80
        let score = HRVAnalyzer.hrvScore(trend: trend)
        #expect(score >= 60)
        #expect(score <= 100)
        #expect(score == 80)
    }

    @Test("HRV score reduced by 10 when trend is declining")
    func hrvScoreDecliningPenalty() {
        let stableTrend = HRVAnalyzer.HRVTrend(
            currentHRV: 50,
            sevenDayAverage: 50,
            thirtyDayAverage: 50,
            trend: .stable,
            percentChangeFromBaseline: 0,
            isSignificantChange: false
        )
        let decliningTrend = HRVAnalyzer.HRVTrend(
            currentHRV: 50,
            sevenDayAverage: 50,
            thirtyDayAverage: 50,
            trend: .declining,
            percentChangeFromBaseline: -10,
            isSignificantChange: false
        )
        let stableScore = HRVAnalyzer.hrvScore(trend: stableTrend)
        let decliningScore = HRVAnalyzer.hrvScore(trend: decliningTrend)
        #expect(stableScore - decliningScore == 10)
    }

    @Test("HRV score clamped between 0 and 100")
    func hrvScoreClamped() {
        // Very low ratio to push score toward 0
        let lowTrend = HRVAnalyzer.HRVTrend(
            currentHRV: 5,
            sevenDayAverage: 10,
            thirtyDayAverage: 60,
            trend: .declining,
            percentChangeFromBaseline: -80,
            isSignificantChange: true
        )
        let lowScore = HRVAnalyzer.hrvScore(trend: lowTrend)
        #expect(lowScore >= 0)
        #expect(lowScore <= 100)

        // Very high ratio to push score above 100
        let highTrend = HRVAnalyzer.HRVTrend(
            currentHRV: 100,
            sevenDayAverage: 90,
            thirtyDayAverage: 40,
            trend: .improving,
            percentChangeFromBaseline: 50,
            isSignificantChange: true
        )
        let highScore = HRVAnalyzer.hrvScore(trend: highTrend)
        #expect(highScore >= 0)
        #expect(highScore <= 100)
    }
}
