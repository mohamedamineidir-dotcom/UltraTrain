import Foundation
import Testing
@testable import UltraTrain

@Suite("FatiguePatternDetector Tests")
struct FatiguePatternDetectorTests {

    // MARK: - Helpers

    private func makeRun(
        daysAgo: Int,
        pace: Double = 360,
        heartRate: Int? = 145,
        distance: Double = 10,
        elevation: Double = 200,
        duration: TimeInterval = 3600,
        rpe: Int? = nil
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
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0,
            rpe: rpe
        )
    }

    private func makeSleepEntry(
        daysAgo: Int,
        totalSleep: TimeInterval = 7 * 3600,
        efficiency: Double = 0.90
    ) -> SleepEntry {
        let date = Calendar.current.date(
            byAdding: .day, value: -daysAgo, to: Date.now
        ) ?? Date.distantPast

        return SleepEntry(
            id: UUID(),
            date: date,
            totalSleepDuration: totalSleep,
            deepSleepDuration: totalSleep * 0.2,
            remSleepDuration: totalSleep * 0.25,
            coreSleepDuration: totalSleep * 0.55,
            sleepEfficiency: efficiency,
            bedtime: date,
            wakeTime: date.addingTimeInterval(totalSleep / efficiency),
            timeInBed: totalSleep / efficiency
        )
    }

    // MARK: - Tests

    @Test("No data returns empty patterns")
    func noData_returnsEmptyPatterns() {
        let input = FatiguePatternDetector.Input(
            recentRuns: [],
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)

        #expect(result.isEmpty)
    }

    @Test("Pace decline detected when second half is slower at moderate HR")
    func paceDecline_detected() {
        // Need at least trendMinDataPoints (5) moderate-HR runs
        // First half: faster pace, second half: slower pace (>5% increase)
        var runs: [CompletedRun] = []
        // First 3 runs: pace 340 s/km
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 13 - i, pace: 340, heartRate: 150))
        }
        // Last 3 runs: pace 375 s/km (~10% slower)
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 5 - i, pace: 375, heartRate: 150))
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let pacePattern = result.first { $0.type == .paceDecline }

        #expect(pacePattern != nil)
        #expect(pacePattern?.severity != nil)
    }

    @Test("HR drift detected when heart rate rises at similar pace")
    func hrDrift_detected() {
        // Need at least 5 runs with HR data, similar pace, but rising HR
        var runs: [CompletedRun] = []
        // First 3 runs: lower HR
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 13 - i, pace: 350, heartRate: 140))
        }
        // Last 3 runs: higher HR at same pace (~12% higher)
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 5 - i, pace: 350, heartRate: 158))
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let hrPattern = result.first { $0.type == .heartRateDrift }

        #expect(hrPattern != nil)
    }

    @Test("Sleep decline detected when recent nights are significantly worse")
    func sleepDecline_detected() {
        // Need at least 7 entries, with recent 3 much worse than baseline
        var entries: [SleepEntry] = []
        // Baseline: good sleep (7h, 90% efficiency) for first 7 nights
        for i in 0..<7 {
            entries.append(makeSleepEntry(daysAgo: 10 - i, totalSleep: 7 * 3600, efficiency: 0.90))
        }
        // Recent 3 nights: poor sleep (4h, 60% efficiency)
        for i in 0..<3 {
            entries.append(makeSleepEntry(daysAgo: 3 - i, totalSleep: 4 * 3600, efficiency: 0.60))
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: [],
            sleepHistory: entries,
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let sleepPattern = result.first { $0.type == .sleepQualityDecline }

        #expect(sleepPattern != nil)
        #expect(sleepPattern?.severity != nil)
    }

    @Test("RPE trend detected when perceived effort rises")
    func rpeTrend_detected() {
        // Need at least 5 runs with RPE, rising trend (>1.5 point rise)
        var runs: [CompletedRun] = []
        // First 3 runs: RPE 4-5
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 13 - i, rpe: 4))
        }
        // Last 3 runs: RPE 7-8
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 5 - i, rpe: 7))
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let rpePattern = result.first { $0.type == .rpeTrend }

        #expect(rpePattern != nil)
    }

    @Test("Compound fatigue created when 2 or more patterns present")
    func compoundFatigue_when2PlusPatterns() {
        // Create runs that trigger both pace decline and RPE trend
        var runs: [CompletedRun] = []
        // First 3: fast pace, low RPE
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 13 - i, pace: 340, heartRate: 150, rpe: 4))
        }
        // Last 3: slow pace, high RPE
        for i in 0..<3 {
            runs.append(makeRun(daysAgo: 5 - i, pace: 380, heartRate: 150, rpe: 8))
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let compoundPattern = result.first { $0.type == .compoundFatigue }

        #expect(compoundPattern != nil)
        #expect(compoundPattern?.severity == .significant)
    }

    @Test("Insufficient runs return nil for pace decline detection")
    func insufficientRuns_noPaceDecline() {
        // Only 3 runs (below trendMinDataPoints of 5)
        let runs = (0..<3).map { i in
            makeRun(daysAgo: i, pace: 360, heartRate: 150)
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let pacePattern = result.first { $0.type == .paceDecline }

        #expect(pacePattern == nil)
    }

    @Test("Insufficient sleep entries return nil for sleep decline")
    func insufficientSleep_noSleepDecline() {
        // Only 4 entries (below the 7 minimum)
        let entries = (0..<4).map { i in
            makeSleepEntry(daysAgo: i)
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: [],
            sleepHistory: entries,
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)
        let sleepPattern = result.first { $0.type == .sleepQualityDecline }

        #expect(sleepPattern == nil)
    }

    @Test("Severity classification: mild for small changes, significant for large")
    func severityClassification() {
        // Create runs with ~6% pace increase -> mild
        var mildRuns: [CompletedRun] = []
        for i in 0..<3 {
            mildRuns.append(makeRun(daysAgo: 13 - i, pace: 340, heartRate: 150))
        }
        for i in 0..<3 {
            mildRuns.append(makeRun(daysAgo: 5 - i, pace: 362, heartRate: 150))
        }

        let mildInput = FatiguePatternDetector.Input(
            recentRuns: mildRuns,
            sleepHistory: [],
            recoveryScores: []
        )
        let mildResult = FatiguePatternDetector.detect(input: mildInput)
        let mildPattern = mildResult.first { $0.type == .paceDecline }

        if let mildPattern {
            #expect(mildPattern.severity == .mild)
        }

        // Create runs with ~20% pace increase -> significant
        var significantRuns: [CompletedRun] = []
        for i in 0..<3 {
            significantRuns.append(makeRun(daysAgo: 13 - i, pace: 340, heartRate: 150))
        }
        for i in 0..<3 {
            significantRuns.append(makeRun(daysAgo: 5 - i, pace: 410, heartRate: 150))
        }

        let significantInput = FatiguePatternDetector.Input(
            recentRuns: significantRuns,
            sleepHistory: [],
            recoveryScores: []
        )
        let significantResult = FatiguePatternDetector.detect(input: significantInput)
        let significantPattern = significantResult.first { $0.type == .paceDecline }

        #expect(significantPattern != nil)
        #expect(significantPattern?.severity == .significant)
    }

    @Test("Runs outside detection window are excluded")
    func oldRuns_excluded() {
        // Runs from 30 days ago (outside 14-day window)
        let runs = (0..<6).map { i in
            makeRun(daysAgo: 30 + i, pace: 340 + Double(i) * 20, heartRate: 150)
        }

        let input = FatiguePatternDetector.Input(
            recentRuns: runs,
            sleepHistory: [],
            recoveryScores: []
        )

        let result = FatiguePatternDetector.detect(input: input)

        #expect(result.isEmpty)
    }
}
