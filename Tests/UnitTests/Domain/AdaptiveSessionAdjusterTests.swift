import Foundation
import Testing
@testable import UltraTrain

@Suite("AdaptiveSessionAdjuster Tests")
struct AdaptiveSessionAdjusterTests {

    // MARK: - Helpers

    private func makeSession(
        type: SessionType = .tempo,
        distance: Double = 12.0,
        duration: TimeInterval = 4200,
        intensity: Intensity = .hard
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: distance,
            plannedElevationGainM: 300,
            plannedDuration: duration,
            intensity: intensity,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    private func makeReadiness(status: ReadinessStatus) -> ReadinessScore {
        let score: Int
        let recommendation: SessionIntensityRecommendation
        switch status {
        case .primed:
            score = 90
            recommendation = .highIntensity
        case .ready:
            score = 75
            recommendation = .moderateEffort
        case .moderate:
            score = 60
            recommendation = .easyOnly
        case .fatigued:
            score = 40
            recommendation = .activeRecovery
        case .needsRest:
            score = 15
            recommendation = .restDay
        }
        return ReadinessScore(
            overallScore: score,
            recoveryComponent: score,
            hrvComponent: score,
            trainingLoadComponent: score,
            status: status,
            sessionRecommendation: recommendation
        )
    }

    private func makeFatiguePattern(
        type: FatiguePatternType,
        severity: FatigueSeverity = .mild
    ) -> FatiguePattern {
        FatiguePattern(
            id: UUID(),
            type: type,
            severity: severity,
            evidence: [],
            recommendation: "Test",
            suggestedDeloadDays: 3,
            detectedDate: .now
        )
    }

    private func makeRecoveryScore(sleepQuality: Int = 70) -> RecoveryScore {
        RecoveryScore(
            id: UUID(),
            date: .now,
            overallScore: 70,
            sleepQualityScore: sleepQuality,
            sleepConsistencyScore: 70,
            restingHRScore: 70,
            trainingLoadBalanceScore: 70,
            recommendation: "Test",
            status: .good
        )
    }

    private func makeWeather(temp: Double = 20) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temp,
            apparentTemperatureCelsius: temp,
            humidity: 0.5,
            windSpeedKmh: 10,
            windDirectionDegrees: 180,
            condition: .clear,
            uvIndex: 5,
            precipitationChance: 0,
            symbolName: "sun.max",
            capturedAt: .now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
    }

    // MARK: - Tests

    @Test("No adjustment needed for ready readiness with easy session")
    func noAdjustment_readyAndEasySession() {
        let session = makeSession(type: .recovery, intensity: .easy)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: makeReadiness(status: .ready),
            recoveryScore: makeRecoveryScore(),
            fatiguePatterns: [],
            weather: nil
        )

        #expect(result == nil)
    }

    @Test("Compound fatigue forces recovery regardless of session type")
    func compoundFatigue_forcesRecovery() {
        let session = makeSession(type: .intervals, intensity: .hard)
        let compound = makeFatiguePattern(type: .compoundFatigue, severity: .significant)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: makeReadiness(status: .ready),
            recoveryScore: nil,
            fatiguePatterns: [compound],
            weather: nil
        )

        #expect(result != nil)
        #expect(result?.adjustedType == .recovery)
        #expect(result?.adjustedIntensity == .easy)
        #expect(result?.reason == .compoundFatigue)
        #expect(result?.confidencePercent == 90)
        #expect(result?.adjustedDistanceKm ?? 0 <= 5.0)
    }

    @Test("Fatigued readiness downgrades hard session to recovery")
    func fatiguedReadiness_downgradesHard() {
        let session = makeSession(type: .intervals, intensity: .hard)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: makeReadiness(status: .fatigued),
            recoveryScore: nil,
            fatiguePatterns: [],
            weather: nil
        )

        #expect(result != nil)
        #expect(result?.adjustedType == .recovery)
        #expect(result?.adjustedIntensity == .easy)
        #expect(result?.reason == .readinessTooLow)
        #expect(result?.confidencePercent == 80)
    }

    @Test("Primed readiness upgrades recovery to tempo")
    func primedReadiness_upgradesRecoveryToTempo() {
        let session = makeSession(type: .recovery, distance: 6, intensity: .easy)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: makeReadiness(status: .primed),
            recoveryScore: nil,
            fatiguePatterns: [],
            weather: nil
        )

        #expect(result != nil)
        #expect(result?.adjustedType == .tempo)
        #expect(result?.adjustedIntensity == .moderate)
        #expect(result?.reason == .readinessHighUpgrade)
        #expect(result?.adjustedDistanceKm ?? 0 >= 8.0)
    }

    @Test("Poor sleep reduces long run distance by 20%")
    func poorSleep_reducesLongRunDistance() {
        let session = makeSession(type: .longRun, distance: 25.0, duration: 9000, intensity: .moderate)
        let poorSleepRecovery = makeRecoveryScore(sleepQuality: 30)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: nil,
            recoveryScore: poorSleepRecovery,
            fatiguePatterns: [],
            weather: nil
        )

        #expect(result != nil)
        #expect(result?.reason == .poorSleep)
        #expect(result?.adjustedDistanceKm ?? 0 == 25.0 * 0.8)
        #expect(result?.adjustedDuration ?? 0 == 9000 * 0.8)
        #expect(result?.adjustedType == .longRun)
    }

    @Test("Extreme heat reduces hard session intensity and volume")
    func extremeHeat_reducesHardSession() {
        let session = makeSession(type: .intervals, distance: 15.0, duration: 5400, intensity: .hard)

        let result = AdaptiveSessionAdjuster.adjust(
            session: session,
            readiness: nil,
            recoveryScore: nil,
            fatiguePatterns: [],
            weather: makeWeather(temp: 35)
        )

        #expect(result != nil)
        #expect(result?.reason == .weatherConditions)
        #expect(result?.adjustedIntensity == .moderate)
        #expect(result?.adjustedDistanceKm ?? 0 < 15.0)
        #expect(result?.confidencePercent == 80)
    }
}
