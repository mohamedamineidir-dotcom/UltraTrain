import Foundation
import Testing
@testable import UltraTrain

@Suite("SessionOptimizer Tests")
struct SessionOptimizerTests {

    // MARK: - Helpers

    private func makeSession(
        type: SessionType = .tempo,
        distance: Double = 12.0,
        elevation: Double = 300,
        duration: TimeInterval = 4200,
        intensity: Intensity = .hard,
        targetHRZone: Int? = 3
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: distance,
            plannedElevationGainM: elevation,
            plannedDuration: duration,
            intensity: intensity,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil,
            targetHeartRateZone: targetHRZone
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

    private func makeWeather(
        temp: Double = 20,
        wind: Double = 10
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temp,
            apparentTemperatureCelsius: temp,
            humidity: 0.5,
            windSpeedKmh: wind,
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

    @Test("Compound fatigue forces rest day regardless of planned session")
    func compoundFatigue_forcesRest() {
        let session = makeSession(type: .intervals, intensity: .hard)
        let compoundPattern = makeFatiguePattern(type: .compoundFatigue, severity: .significant)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .ready),
            fatiguePatterns: [compoundPattern],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.recommendedType == .rest)
        #expect(result.distanceKm == 0)
        #expect(result.elevationGainM == 0)
        #expect(result.duration == 0)
        #expect(result.confidencePercent == 90)
    }

    @Test("Fatigued readiness downgrades hard session to recovery")
    func fatiguedReadiness_downgradesHardToRecovery() {
        let session = makeSession(type: .intervals, intensity: .hard)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .fatigued),
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.recommendedType == .recovery)
        #expect(result.intensity == .easy)
        #expect(result.distanceKm <= 8.0)
        #expect(result.duration <= 3600)
        #expect(result.targetHeartRateZone == 1)
        #expect(result.confidencePercent == 80)
    }

    @Test("Primed readiness upgrades easy session to tempo in build phase")
    func primedReadiness_upgradesEasyToTempo() {
        let session = makeSession(type: .recovery, distance: 6, intensity: .easy)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .primed),
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.recommendedType == .tempo)
        #expect(result.intensity == .moderate)
        #expect(result.distanceKm >= 8.0)
        #expect(result.targetHeartRateZone == 3)
        #expect(result.confidencePercent == 75)
    }

    @Test("Phase constraint prevents intervals during taper")
    func phaseConstraint_noIntervalsDuringTaper() {
        let session = makeSession(type: .intervals, intensity: .hard)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .taper,
            readiness: makeReadiness(status: .ready),
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.recommendedType == .tempo)
        #expect(result.intensity == .moderate)
        #expect(result.reasoning.contains("taper"))
    }

    @Test("Weather heat reduces intensity and volume")
    func weatherHeat_reducesIntensityAndVolume() {
        let session = makeSession(type: .tempo, distance: 15.0, intensity: .hard, targetHRZone: 4)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .ready),
            fatiguePatterns: [],
            weather: makeWeather(temp: 35),
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        // Heat > 30C reduces distance by 0.85
        #expect(result.distanceKm < 15.0)
        #expect(result.intensity == .moderate)
        #expect(result.reasoning.contains("heat"))
    }

    @Test("No readiness data returns low confidence")
    func noReadinessData_lowConfidence() {
        let session = makeSession(type: .tempo, intensity: .hard)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: nil,
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.confidencePercent == 50)
        #expect(result.reasoning.contains("No readiness data"))
    }

    @Test("Time constraint scales session proportionally")
    func timeConstraint_scalesSession() {
        let session = makeSession(
            type: .longRun, distance: 20.0, elevation: 500,
            duration: 7200, intensity: .moderate
        )

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .ready),
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: 60  // 3600s, half the planned 7200s
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.duration <= 3600)
        // Distance should be roughly halved
        #expect(result.distanceKm < 15.0)
        #expect(result.reasoning.contains("60 min"))
    }

    @Test("Moderate readiness reduces max effort to hard")
    func moderateReadiness_reducesMaxEffortToHard() {
        let session = makeSession(type: .intervals, intensity: .maxEffort)

        let input = SessionOptimizer.Input(
            plannedSession: session,
            currentPhase: .build,
            readiness: makeReadiness(status: .moderate),
            fatiguePatterns: [],
            weather: nil,
            availableTimeMinutes: nil
        )

        let result = SessionOptimizer.optimize(input: input)

        #expect(result.intensity == .hard)
        #expect(result.confidencePercent == 70)
        #expect(result.reasoning.contains("moderate"))
    }
}
