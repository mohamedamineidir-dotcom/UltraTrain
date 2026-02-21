import Foundation
import Testing
@testable import UltraTrain

@Suite("RecoveryScoreCalculator Tests")
struct RecoveryScoreCalculatorTests {

    // MARK: - Helpers

    private func makeSleepEntry(
        hours: Double = 8,
        deepPercent: Double = 0.20,
        efficiency: Double = 0.90,
        bedtime: Date = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date.now)!,
        wakeTime: Date = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date.now)!
    ) -> SleepEntry {
        let totalSleep = hours * 3600
        let timeInBed = totalSleep / max(efficiency, 0.01)
        return SleepEntry(
            id: UUID(),
            date: Date.now,
            totalSleepDuration: totalSleep,
            deepSleepDuration: totalSleep * deepPercent,
            remSleepDuration: totalSleep * 0.25,
            coreSleepDuration: totalSleep * (1 - deepPercent - 0.25),
            sleepEfficiency: efficiency,
            bedtime: bedtime,
            wakeTime: wakeTime,
            timeInBed: timeInBed
        )
    }

    private func makeSleepHistory(count: Int = 7, hours: Double = 8) -> [SleepEntry] {
        (0..<count).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date.now)!
            let bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: date)!
            let wakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date)!
            return SleepEntry(
                id: UUID(),
                date: date,
                totalSleepDuration: hours * 3600,
                deepSleepDuration: hours * 3600 * 0.20,
                remSleepDuration: hours * 3600 * 0.25,
                coreSleepDuration: hours * 3600 * 0.55,
                sleepEfficiency: 0.90,
                bedtime: bedtime,
                wakeTime: wakeTime,
                timeInBed: hours * 3600 / 0.90
            )
        }
    }

    private func makeSnapshot(form: Double = 10) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: .now,
            fitness: 50,
            fatigue: 50 - form,
            form: form,
            weeklyVolumeKm: 40,
            weeklyElevationGainM: 800,
            weeklyDuration: 14400,
            acuteToChronicRatio: 1.0,
            monotony: 1.0
        )
    }

    // MARK: - Good Recovery

    @Test("Good sleep, normal HR, positive form produces high score")
    func goodRecovery() {
        let sleep = makeSleepEntry(hours: 8, deepPercent: 0.20, efficiency: 0.90)
        let history = makeSleepHistory(count: 7, hours: 8)
        let snapshot = makeSnapshot(form: 15)

        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 52,
            fitnessSnapshot: snapshot
        )

        #expect(score.overallScore >= 70)
        #expect(score.status == .excellent || score.status == .good)
    }

    // MARK: - Poor Sleep

    @Test("Poor sleep produces low sleep quality score")
    func poorSleep() {
        let sleep = makeSleepEntry(hours: 3, deepPercent: 0.0, efficiency: 0.30)
        let history = makeSleepHistory(count: 7, hours: 3)

        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 52,
            fitnessSnapshot: makeSnapshot(form: 10)
        )

        #expect(score.sleepQualityScore < 50)
        #expect(score.overallScore <= 70)
    }

    // MARK: - No Sleep Data (Graceful Degradation)

    @Test("No sleep data produces score based on HR and fitness only")
    func noSleepData() {
        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: nil,
            sleepHistory: [],
            currentRestingHR: 50,
            baselineRestingHR: 52,
            fitnessSnapshot: makeSnapshot(form: 10)
        )

        // Should still produce a reasonable score from HR + fitness
        #expect(score.overallScore > 0)
        #expect(score.recommendation.contains("sleep tracking"))
    }

    // MARK: - Elevated HR

    @Test("Elevated resting HR reduces score")
    func elevatedHR() {
        let sleep = makeSleepEntry()
        let history = makeSleepHistory()

        let normalHR = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot()
        )

        let elevatedHR = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 58,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot()
        )

        #expect(elevatedHR.restingHRScore < normalHR.restingHRScore)
        #expect(elevatedHR.overallScore < normalHR.overallScore)
    }

    // MARK: - Negative Form

    @Test("Negative form reduces training load balance score")
    func negativeForm() {
        let sleep = makeSleepEntry()
        let history = makeSleepHistory()

        let freshScore = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 15)
        )

        let fatiguedScore = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: -25)
        )

        #expect(fatiguedScore.trainingLoadBalanceScore < freshScore.trainingLoadBalanceScore)
        #expect(fatiguedScore.overallScore < freshScore.overallScore)
    }

    // MARK: - Score Clamping

    @Test("Score clamped to 0-100 range")
    func scoreClamped() {
        // Best possible inputs
        let bestScore = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(hours: 8, deepPercent: 0.20, efficiency: 1.0),
            sleepHistory: makeSleepHistory(count: 7, hours: 8),
            currentRestingHR: 48,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 20)
        )
        #expect(bestScore.overallScore <= 100)

        // Worst possible inputs
        let worstScore = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(hours: 1, deepPercent: 0.0, efficiency: 0.1),
            sleepHistory: makeSleepHistory(count: 7, hours: 2),
            currentRestingHR: 70,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: -35)
        )
        #expect(worstScore.overallScore >= 0)
    }

    // MARK: - Status Mapping

    @Test("Status maps correctly to score ranges")
    func statusMapping() {
        let excellent = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(hours: 8, deepPercent: 0.20, efficiency: 0.95),
            sleepHistory: makeSleepHistory(count: 7, hours: 8),
            currentRestingHR: 48,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 15)
        )
        // Score should be high
        if excellent.overallScore >= 80 {
            #expect(excellent.status == .excellent)
        }

        let poor = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(hours: 3, deepPercent: 0.05, efficiency: 0.4),
            sleepHistory: makeSleepHistory(count: 7, hours: 3),
            currentRestingHR: 60,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: -25)
        )
        #expect(poor.overallScore < 60)
    }

    // MARK: - All Nil Inputs

    @Test("All nil inputs produce neutral score")
    func allNilInputs() {
        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: nil,
            sleepHistory: [],
            currentRestingHR: nil,
            baselineRestingHR: nil,
            fitnessSnapshot: nil
        )

        // Default scores (50 each) with 50/50 weighting = 50
        #expect(score.overallScore == 50)
        #expect(score.status == .moderate)
    }

    // MARK: - HR at Baseline

    @Test("HR at or below baseline gives perfect HR score")
    func hrAtBaseline() {
        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: nil,
            sleepHistory: [],
            currentRestingHR: 48,
            baselineRestingHR: 50,
            fitnessSnapshot: nil
        )

        #expect(score.restingHRScore == 100)
    }

    // MARK: - Recommendation Content

    @Test("Low score produces rest recommendation")
    func lowScoreRecommendation() {
        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(hours: 3, deepPercent: 0.05, efficiency: 0.3),
            sleepHistory: makeSleepHistory(count: 7, hours: 3),
            currentRestingHR: 65,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: -30)
        )

        #expect(score.recommendation.lowercased().contains("low") || score.recommendation.lowercased().contains("rest") || score.recommendation.lowercased().contains("recovery"))
    }

    // MARK: - HRV Integration

    @Test("HRV component included when provided")
    func hrvComponentIncluded() {
        let sleep = makeSleepEntry(hours: 8, deepPercent: 0.20, efficiency: 0.90)
        let history = makeSleepHistory(count: 7, hours: 8)

        let scoreWithHRV = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 10),
            hrvScore: 90
        )

        #expect(scoreWithHRV.hrvScore == 90)
    }

    @Test("HRV rebalances weights when present")
    func hrvRebalancesWeights() {
        let sleep = makeSleepEntry(hours: 8, deepPercent: 0.20, efficiency: 0.90)
        let history = makeSleepHistory(count: 7, hours: 8)

        let withoutHRV = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 10)
        )

        let withHRV = RecoveryScoreCalculator.calculate(
            lastNightSleep: sleep,
            sleepHistory: history,
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot(form: 10),
            hrvScore: 90
        )

        #expect(withHRV.overallScore != withoutHRV.overallScore)
        #expect(withHRV.hrvScore == 90)
        #expect(withoutHRV.hrvScore == 0)
    }

    @Test("HRV score defaults to 0 when unavailable")
    func hrvDefaultsToZero() {
        let score = RecoveryScoreCalculator.calculate(
            lastNightSleep: makeSleepEntry(),
            sleepHistory: makeSleepHistory(),
            currentRestingHR: 50,
            baselineRestingHR: 50,
            fitnessSnapshot: makeSnapshot()
        )

        #expect(score.hrvScore == 0)
    }
}
