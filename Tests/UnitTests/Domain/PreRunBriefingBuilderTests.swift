import Foundation
import Testing
@testable import UltraTrain

@Suite("PreRunBriefingBuilder Tests")
struct PreRunBriefingBuilderTests {

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

    private func makeRecentRun(daysAgo: Int, distance: Double = 10, elevation: Double = 200) -> CompletedRun {
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
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 165,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeAthlete(weight: Double = 70) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(
                byAdding: .year, value: -30, to: Date.now
            ) ?? Date.distantPast,
            weightKg: weight,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 42,
            preferredUnit: .metric
        )
    }

    // MARK: - Tests

    @Test("Builds briefing with all data populated")
    func buildsBriefing_allData() {
        let session = makeSession(type: .tempo)
        let readiness = makeReadiness(status: .ready)
        let runs = [makeRecentRun(daysAgo: 1), makeRecentRun(daysAgo: 3)]

        let briefing = PreRunBriefingBuilder.build(
            session: session,
            readinessScore: readiness,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [],
            recentRuns: runs,
            athlete: makeAthlete()
        )

        #expect(briefing.readinessStatus == .good)
        #expect(briefing.readinessScore == 75)
        #expect(briefing.pacingRecommendation != nil)
        #expect(briefing.focusPoint.isEmpty == false)
        #expect(briefing.recentPerformanceSummary != nil)
    }

    @Test("No readiness data still produces a focus point")
    func noReadinessData_produceFocusPoint() {
        let session = makeSession(type: .longRun)

        let briefing = PreRunBriefingBuilder.build(
            session: session,
            readinessScore: nil,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [],
            recentRuns: [],
            athlete: nil
        )

        #expect(briefing.readinessStatus == nil)
        #expect(briefing.readinessScore == nil)
        #expect(briefing.focusPoint.isEmpty == false)
        // Pacing recommendation defaults to "no readiness data" message
        #expect(briefing.pacingRecommendation?.contains("No readiness data") == true)
    }

    @Test("Long run (>= 2 hours) gets nutrition reminder with calorie guidance")
    func longRun_getsNutritionReminder() {
        // Duration of 2.5 hours (9000 seconds) > 2 hours threshold
        let session = makeSession(type: .longRun, duration: 9000)
        let athlete = makeAthlete(weight: 70)

        let briefing = PreRunBriefingBuilder.build(
            session: session,
            readinessScore: nil,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [],
            recentRuns: [],
            athlete: athlete
        )

        #expect(briefing.nutritionReminder != nil)
        // Should contain calorie range: 70*4=280 to 70*6=420
        #expect(briefing.nutritionReminder?.contains("280") == true)
        #expect(briefing.nutritionReminder?.contains("420") == true)
    }

    @Test("Short run (< 90 min) has no nutrition reminder")
    func shortRun_noNutritionReminder() {
        // Duration of 45 minutes (2700s) < 90 min
        let session = makeSession(type: .tempo, duration: 2700)

        let briefing = PreRunBriefingBuilder.build(
            session: session,
            readinessScore: nil,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [],
            recentRuns: [],
            athlete: nil
        )

        #expect(briefing.nutritionReminder == nil)
    }

    @Test("Performance summary computed from last 7 days of runs")
    func performanceSummary_lastSevenDays() {
        let runs = [
            makeRecentRun(daysAgo: 1, distance: 12.0, elevation: 300),
            makeRecentRun(daysAgo: 3, distance: 8.0, elevation: 150),
            makeRecentRun(daysAgo: 10, distance: 20.0, elevation: 500)  // excluded (>7 days ago)
        ]

        let briefing = PreRunBriefingBuilder.build(
            session: nil,
            readinessScore: nil,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [],
            recentRuns: runs,
            athlete: nil
        )

        // Only 2 runs in last 7 days: 12+8 = 20 km, 300+150 = 450 D+
        #expect(briefing.recentPerformanceSummary != nil)
        #expect(briefing.recentPerformanceSummary?.contains("20.0 km") == true)
        #expect(briefing.recentPerformanceSummary?.contains("450 m D+") == true)
        #expect(briefing.recentPerformanceSummary?.contains("2 runs") == true)
    }

    @Test("Adjustment included in briefing when fatigue is detected")
    func adjustmentIncluded_whenFatigueDetected() {
        let session = makeSession(type: .intervals, intensity: .hard)
        let compound = FatiguePattern(
            id: UUID(),
            type: .compoundFatigue,
            severity: .significant,
            evidence: [],
            recommendation: "Rest needed",
            suggestedDeloadDays: 5,
            detectedDate: .now
        )

        let briefing = PreRunBriefingBuilder.build(
            session: session,
            readinessScore: nil,
            recoveryScore: nil,
            weather: nil,
            fatiguePatterns: [compound],
            recentRuns: [],
            athlete: nil
        )

        #expect(briefing.adaptiveAdjustment != nil)
        #expect(briefing.adaptiveAdjustment?.reason == .compoundFatigue)
        #expect(briefing.fatigueAlerts.count == 1)
        // Focus point should reflect the adjustment
        #expect(briefing.focusPoint.contains("fatigue") == true)
    }
}
