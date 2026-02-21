import Foundation
import Testing
@testable import UltraTrain

@Suite("ReadinessCalculator Tests")
struct ReadinessCalculatorTests {

    // MARK: - Helpers

    private func makeRecoveryScore(overall: Int = 70) -> RecoveryScore {
        RecoveryScore(
            id: UUID(), date: .now, overallScore: overall,
            sleepQualityScore: 70, sleepConsistencyScore: 70,
            restingHRScore: 70, trainingLoadBalanceScore: 70,
            recommendation: "Test", status: .good
        )
    }

    private func makeSnapshot(form: Double = 10) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(), date: .now, fitness: 50, fatigue: 50 - form,
            form: form, weeklyVolumeKm: 40, weeklyElevationGainM: 800,
            weeklyDuration: 14400, acuteToChronicRatio: 1.0, monotony: 1.0
        )
    }

    private func makeHRVTrend(
        currentHRV: Double = 45, sevenDayAvg: Double = 45, thirtyDayAvg: Double = 42,
        trend: HRVAnalyzer.TrendDirection = .stable, percentChange: Double = 7,
        isSignificant: Bool = false
    ) -> HRVAnalyzer.HRVTrend {
        HRVAnalyzer.HRVTrend(
            currentHRV: currentHRV, sevenDayAverage: sevenDayAvg,
            thirtyDayAverage: thirtyDayAvg, trend: trend,
            percentChangeFromBaseline: percentChange, isSignificantChange: isSignificant
        )
    }

    // MARK: - Tests

    @Test("High recovery + good HRV + fresh form yields primed status")
    func highRecoveryGoodHRVFreshForm_primed() {
        let recovery = makeRecoveryScore(overall: 90)
        let hrv = makeHRVTrend(
            currentHRV: 55, sevenDayAvg: 52, thirtyDayAvg: 45,
            trend: .improving, percentChange: 15, isSignificant: true
        )
        let snapshot = makeSnapshot(form: 15)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // HRV ratio = 55/45 = 1.22 -> baseScore 100, improving +5 -> clamped 100
        // trainingLoad: form 15 >= 10 -> 100
        // overall = 90*0.40 + 100*0.30 + 100*0.30 = 96
        #expect(result.overallScore >= 85)
        #expect(result.overallScore == 96)
        #expect(result.status == .primed)
        #expect(result.sessionRecommendation == .highIntensity)
    }

    @Test("Moderate recovery + no HRV uses 55/45 weight distribution")
    func moderateRecoveryNoHRV_uses55_45Weights() {
        let recovery = makeRecoveryScore(overall: 70)
        let snapshot = makeSnapshot(form: 10)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: nil, fitnessSnapshot: snapshot
        )

        // hrvComponent must be 0 when no HRV data
        #expect(result.hrvComponent == 0)
        // trainingLoad: form 10 >= 10 -> 100
        // overall = 70*0.55 + 100*0.45 = 38.5 + 45 = 83.5 -> Int = 83
        #expect(result.overallScore == 83)
        #expect(result.trainingLoadComponent == 100)
    }

    @Test("Low recovery + good HRV pulls score down toward moderate/ready")
    func lowRecoveryGoodHRV_pulledDown() {
        let recovery = makeRecoveryScore(overall: 30)
        let hrv = makeHRVTrend()  // stable, ratio ~1.07 -> score ~94
        let snapshot = makeSnapshot(form: 10)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // HRV ratio = 45/42 = 1.071, baseScore = 60 + (1.071-0.9)*200 = 94.2 -> 94
        // trainingLoad: form 10 -> 100
        // overall = 30*0.40 + 94*0.30 + 100*0.30 = 12 + 28.2 + 30 = 70.2 -> 70
        #expect(result.overallScore == 70)
        #expect(result.recoveryComponent == 30)
        #expect(result.overallScore < 85)
    }

    @Test("Nil fitness snapshot defaults training load component to 50")
    func nilFitnessSnapshot_defaultsTrainingLoadTo50() {
        let recovery = makeRecoveryScore(overall: 70)
        let hrv = makeHRVTrend()

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: nil
        )

        // trainingLoadComponent = 50 (default)
        #expect(result.trainingLoadComponent == 50)
        // HRV score ~94
        // overall = 70*0.40 + 94*0.30 + 50*0.30 = 28 + 28.2 + 15 = 71.2 -> 71
        #expect(result.overallScore == 71)
    }

    @Test("Status is primed when score >= 85")
    func statusPrimed_atOrAbove85() {
        let recovery = makeRecoveryScore(overall: 90)
        let hrv = makeHRVTrend(
            currentHRV: 55, sevenDayAvg: 52, thirtyDayAvg: 45,
            trend: .improving, percentChange: 15, isSignificant: true
        )
        let snapshot = makeSnapshot(form: 15)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // overall = 96
        #expect(result.overallScore >= 85)
        #expect(result.status == .primed)
    }

    @Test("Status is ready when score is 70-84")
    func statusReady_at70To84() {
        let recovery = makeRecoveryScore(overall: 75)
        let hrv = makeHRVTrend()  // score ~94
        let snapshot = makeSnapshot(form: 5)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // form=5 -> trainingLoad = Int(100*(5+30)/40) = Int(87.5) = 87
        // overall = 75*0.40 + 94*0.30 + 87*0.30 = 30 + 28.2 + 26.1 = 84.3 -> 84
        #expect(result.overallScore >= 70)
        #expect(result.overallScore < 85)
        #expect(result.status == .ready)
    }

    @Test("Status is moderate when score is 50-69")
    func statusModerate_at50To69() {
        let recovery = makeRecoveryScore(overall: 40)
        let hrv = makeHRVTrend(trend: .declining)
        let snapshot = makeSnapshot(form: -5)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // HRV: ratio=45/42=1.071, baseScore=94.2, declining -10 -> 84
        // trainingLoad: form=-5 -> Int(100*25/40) = 62
        // overall = 40*0.40 + 84*0.30 + 62*0.30 = 16 + 25.2 + 18.6 = 59.8 -> 59
        #expect(result.overallScore >= 50)
        #expect(result.overallScore < 70)
        #expect(result.status == .moderate)
    }

    @Test("Status is fatigued when score is 30-49")
    func statusFatigued_at30To49() {
        let recovery = makeRecoveryScore(overall: 30)
        let hrv = makeHRVTrend(trend: .declining)
        let snapshot = makeSnapshot(form: -20)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // HRV: ratio=45/42=1.071, baseScore=94.2, declining -10 -> 84
        // trainingLoad: form=-20 -> Int(100*10/40) = 25
        // overall = 30*0.40 + 84*0.30 + 25*0.30 = 12 + 25.2 + 7.5 = 44.7 -> 44
        #expect(result.overallScore >= 30)
        #expect(result.overallScore < 50)
        #expect(result.status == .fatigued)
    }

    @Test("Status is needsRest when score < 30")
    func statusNeedsRest_below30() {
        let recovery = makeRecoveryScore(overall: 10)
        let hrv = makeHRVTrend(
            currentHRV: 20, sevenDayAvg: 22, thirtyDayAvg: 42,
            trend: .declining, percentChange: -47, isSignificant: true
        )
        let snapshot = makeSnapshot(form: -30)

        let result = ReadinessCalculator.calculate(
            recoveryScore: recovery, hrvTrend: hrv, fitnessSnapshot: snapshot
        )

        // HRV: ratio=20/42=0.476 < 0.7, baseScore = max(0, 0.476*28.6) = 13.6
        // declining -10 -> 3.6 -> 3
        // trainingLoad: form=-30 -> 0
        // overall = 10*0.40 + 3*0.30 + 0*0.30 = 4 + 0.9 + 0 = 4.9 -> 4
        #expect(result.overallScore < 30)
        #expect(result.status == .needsRest)
    }

    @Test("Session recommendation matches score ranges")
    func recommendationMatchesScoreRanges() {
        // Primed (>=85) -> highIntensity
        let primed = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 90),
            hrvTrend: makeHRVTrend(
                currentHRV: 55, sevenDayAvg: 52, thirtyDayAvg: 45,
                trend: .improving, percentChange: 15, isSignificant: true
            ),
            fitnessSnapshot: makeSnapshot(form: 15)
        )
        #expect(primed.sessionRecommendation == .highIntensity)

        // Ready (70-84) -> moderateEffort
        let ready = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 75),
            hrvTrend: makeHRVTrend(),
            fitnessSnapshot: makeSnapshot(form: 5)
        )
        #expect(ready.sessionRecommendation == .moderateEffort)

        // Moderate (50-69) -> easyOnly
        let moderate = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 40),
            hrvTrend: makeHRVTrend(trend: .declining),
            fitnessSnapshot: makeSnapshot(form: -5)
        )
        #expect(moderate.sessionRecommendation == .easyOnly)

        // Fatigued (30-49) -> activeRecovery
        let fatigued = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 30),
            hrvTrend: makeHRVTrend(trend: .declining),
            fitnessSnapshot: makeSnapshot(form: -20)
        )
        #expect(fatigued.sessionRecommendation == .activeRecovery)

        // NeedsRest (<30) -> restDay
        let needsRest = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 10),
            hrvTrend: makeHRVTrend(
                currentHRV: 20, sevenDayAvg: 22, thirtyDayAvg: 42,
                trend: .declining, percentChange: -47, isSignificant: true
            ),
            fitnessSnapshot: makeSnapshot(form: -30)
        )
        #expect(needsRest.sessionRecommendation == .restDay)
    }

    @Test("Score is clamped to 0-100 range with extreme inputs")
    func scoreClamped_extremeInputs() {
        // Maximum possible inputs
        let highResult = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 100),
            hrvTrend: makeHRVTrend(
                currentHRV: 80, sevenDayAvg: 75, thirtyDayAvg: 40,
                trend: .improving, percentChange: 50, isSignificant: true
            ),
            fitnessSnapshot: makeSnapshot(form: 50)
        )
        #expect(highResult.overallScore <= 100)
        #expect(highResult.overallScore >= 0)

        // Minimum possible inputs
        let lowResult = ReadinessCalculator.calculate(
            recoveryScore: makeRecoveryScore(overall: 0),
            hrvTrend: makeHRVTrend(
                currentHRV: 5, sevenDayAvg: 8, thirtyDayAvg: 50,
                trend: .declining, percentChange: -84, isSignificant: true
            ),
            fitnessSnapshot: makeSnapshot(form: -50)
        )
        #expect(lowResult.overallScore >= 0)
        #expect(lowResult.overallScore <= 100)
    }
}
