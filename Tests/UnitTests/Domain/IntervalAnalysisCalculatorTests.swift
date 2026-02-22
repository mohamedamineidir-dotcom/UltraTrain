import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalAnalysisCalculator Tests")
struct IntervalAnalysisCalculatorTests {

    // MARK: - Helpers

    private func makeWorkSplit(
        pace: Double,
        duration: TimeInterval = 240,
        distance: Double = 1.0,
        heartRate: Int? = nil
    ) -> IntervalSplit {
        IntervalSplit(
            id: UUID(),
            phaseIndex: 0,
            phaseType: .work,
            startTime: 0,
            endTime: duration,
            distanceKm: distance,
            averagePaceSecondsPerKm: pace,
            averageHeartRate: heartRate,
            maxHeartRate: heartRate.map { $0 + 10 }
        )
    }

    private func makeRecoverySplit(
        pace: Double = 360,
        duration: TimeInterval = 120,
        distance: Double = 0.4,
        heartRate: Int? = nil
    ) -> IntervalSplit {
        IntervalSplit(
            id: UUID(),
            phaseIndex: 1,
            phaseType: .recovery,
            startTime: 0,
            endTime: duration,
            distanceKm: distance,
            averagePaceSecondsPerKm: pace,
            averageHeartRate: heartRate,
            maxHeartRate: heartRate.map { $0 + 5 }
        )
    }

    // MARK: - Analyze with multiple splits

    @Test("Analyze separates work and recovery splits correctly")
    func analyzeSeparatesSplits() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240),
            makeRecoverySplit(),
            makeWorkSplit(pace: 250),
            makeRecoverySplit(),
            makeWorkSplit(pace: 245)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.workSplits.count == 3)
        #expect(result.recoverySplits.count == 2)
    }

    @Test("Analyze calculates total work and recovery time")
    func analyzeTotalTimes() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240, duration: 240),
            makeRecoverySplit(duration: 120),
            makeWorkSplit(pace: 250, duration: 250),
            makeRecoverySplit(duration: 120)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.totalWorkTime == 490)
        #expect(result.totalRecoveryTime == 240)
    }

    @Test("Analyze calculates work to rest ratio")
    func analyzeWorkToRestRatio() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240, duration: 240),
            makeRecoverySplit(duration: 120),
            makeWorkSplit(pace: 240, duration: 240),
            makeRecoverySplit(duration: 120)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        // totalWork: 480, totalRecovery: 240
        #expect(result.workToRestRatio == 2.0)
    }

    // MARK: - Fastest and Slowest

    @Test("fastestWorkSplit returns the split with lowest pace")
    func fastestWorkSplit() {
        let fast = makeWorkSplit(pace: 220)
        let medium = makeWorkSplit(pace: 240)
        let slow = makeWorkSplit(pace: 260)
        let splits: [IntervalSplit] = [medium, fast, slow]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.fastestWorkSplit?.averagePaceSecondsPerKm == 220)
    }

    @Test("slowestWorkSplit returns the split with highest pace")
    func slowestWorkSplit() {
        let fast = makeWorkSplit(pace: 220)
        let medium = makeWorkSplit(pace: 240)
        let slow = makeWorkSplit(pace: 260)
        let splits: [IntervalSplit] = [medium, fast, slow]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.slowestWorkSplit?.averagePaceSecondsPerKm == 260)
    }

    // MARK: - Average Work Pace

    @Test("averageWorkPace is the mean of work split paces")
    func averageWorkPaceCalculation() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240),
            makeWorkSplit(pace: 250),
            makeWorkSplit(pace: 260)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.averageWorkPace == 250)
    }

    @Test("averageWorkPace ignores recovery splits")
    func averageWorkPaceIgnoresRecovery() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240),
            makeRecoverySplit(pace: 400),
            makeWorkSplit(pace: 260)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.averageWorkPace == 250)
    }

    // MARK: - Pace Consistency

    @Test("paceConsistencyPercent is 100 when all paces identical")
    func paceConsistencyPerfect() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240),
            makeWorkSplit(pace: 240),
            makeWorkSplit(pace: 240)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.paceConsistencyPercent == 100)
    }

    @Test("paceConsistencyPercent is 100 when only one work split")
    func paceConsistencySingleSplit() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.paceConsistencyPercent == 100)
    }

    @Test("paceConsistencyPercent decreases with more pace variation")
    func paceConsistencyDecreasesWithVariation() {
        let consistentSplits: [IntervalSplit] = [
            makeWorkSplit(pace: 240),
            makeWorkSplit(pace: 242),
            makeWorkSplit(pace: 238)
        ]

        let inconsistentSplits: [IntervalSplit] = [
            makeWorkSplit(pace: 200),
            makeWorkSplit(pace: 280),
            makeWorkSplit(pace: 240)
        ]

        let consistentResult = IntervalAnalysisCalculator.analyze(splits: consistentSplits)
        let inconsistentResult = IntervalAnalysisCalculator.analyze(splits: inconsistentSplits)

        #expect(consistentResult.paceConsistencyPercent > inconsistentResult.paceConsistencyPercent)
    }

    // MARK: - Empty Splits

    @Test("Analyze with empty splits returns zero values and nil optionals")
    func emptySpitsReturnsDefaults() {
        let result = IntervalAnalysisCalculator.analyze(splits: [])

        #expect(result.workSplits.isEmpty)
        #expect(result.recoverySplits.isEmpty)
        #expect(result.fastestWorkSplit == nil)
        #expect(result.slowestWorkSplit == nil)
        #expect(result.averageWorkPace == 0)
        #expect(result.paceConsistencyPercent == 100)
        #expect(result.averageWorkHeartRate == nil)
        #expect(result.averageRecoveryHeartRate == nil)
        #expect(result.heartRateRecoveryDelta == nil)
        #expect(result.totalWorkTime == 0)
        #expect(result.totalRecoveryTime == 0)
        #expect(result.workToRestRatio == 0)
    }

    // MARK: - Heart Rate Recovery Delta

    @Test("heartRateRecoveryDelta is work HR minus recovery HR when both present")
    func heartRateRecoveryDeltaPresent() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240, heartRate: 170),
            makeRecoverySplit(heartRate: 130),
            makeWorkSplit(pace: 245, heartRate: 174),
            makeRecoverySplit(heartRate: 134)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        // avg work HR: (170 + 174) / 2 = 172
        // avg recovery HR: (130 + 134) / 2 = 132
        // delta: 172 - 132 = 40
        #expect(result.heartRateRecoveryDelta == 40)
        #expect(result.averageWorkHeartRate == 172)
        #expect(result.averageRecoveryHeartRate == 132)
    }

    @Test("heartRateRecoveryDelta is nil when no HR data present")
    func heartRateRecoveryDeltaNilWithoutHR() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240, heartRate: nil),
            makeRecoverySplit(heartRate: nil)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.heartRateRecoveryDelta == nil)
        #expect(result.averageWorkHeartRate == nil)
        #expect(result.averageRecoveryHeartRate == nil)
    }

    @Test("heartRateRecoveryDelta is nil when only work HR present")
    func heartRateRecoveryDeltaNilWithOnlyWorkHR() {
        let splits: [IntervalSplit] = [
            makeWorkSplit(pace: 240, heartRate: 170),
            makeRecoverySplit(heartRate: nil)
        ]

        let result = IntervalAnalysisCalculator.analyze(splits: splits)

        #expect(result.heartRateRecoveryDelta == nil)
        #expect(result.averageWorkHeartRate == 170)
        #expect(result.averageRecoveryHeartRate == nil)
    }
}
