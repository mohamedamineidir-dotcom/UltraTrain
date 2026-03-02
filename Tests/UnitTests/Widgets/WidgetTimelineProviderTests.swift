import Foundation
import Testing
@testable import UltraTrain

/// Tests for the shared widget data writing pipeline that feeds timeline
/// providers. The timeline providers themselves live in the widget extension
/// target, so we test the WidgetDataWriter -> UserDefaults -> decode path,
/// which is exactly what the providers read at runtime.
@Suite("Widget Timeline Provider Data Pipeline Tests")
struct WidgetTimelineProviderTests {

    private func testDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.timeline.\(UUID().uuidString)")!
    }

    // MARK: - Helpers

    private func makeSession(
        date: Date = .now,
        type: SessionType = .longRun,
        isCompleted: Bool = false,
        isSkipped: Bool = false
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: date,
            type: type,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 5400,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: nil
        )
    }

    private func makePlan(sessions: [TrainingSession]) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 5,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .build,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func makeRace(
        priority: RacePriority = .aRace,
        daysFromNow: Int = 42
    ) -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
            date: Calendar.current.date(byAdding: .day, value: daysFromNow, to: .now)!,
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    // MARK: - Next Session Timeline Data

    @Test("Next session data written to UserDefaults matches what timeline provider reads")
    func nextSessionTimelineData() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: tomorrow, type: .intervals)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeNextSession()

        // Simulate what the timeline provider does: read from UserDefaults
        let data = defaults.data(forKey: WidgetDataKeys.nextSession)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetSessionData.self, from: data!)
        #expect(decoded?.sessionType == "intervals")
        #expect(decoded?.displayName == "Intervals")
        #expect(decoded?.sessionIcon == "timer")
        #expect(decoded?.plannedDistanceKm == 20)
    }

    @Test("Skipped sessions are excluded from next session timeline")
    func skippedSessionsExcluded() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: tomorrow, type: .tempo, isSkipped: true),
            makeSession(date: dayAfter, type: .verticalGain)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeNextSession()

        let data = defaults.data(forKey: WidgetDataKeys.nextSession)
        let decoded = try? JSONDecoder().decode(WidgetSessionData.self, from: data!)
        #expect(decoded?.sessionType == "verticalGain")
        #expect(decoded?.displayName == "Vertical Gain")
    }

    // MARK: - Race Countdown Timeline Data

    @Test("Race countdown only includes A-race and ignores B/C races")
    func raceCountdownIgnoresNonARaces() async {
        let defaults = testDefaults()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [
            makeRace(priority: .bRace, daysFromNow: 14),
            makeRace(priority: .cRace, daysFromNow: 7),
        ]

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: raceRepo,
            defaults: defaults
        )

        await writer.writeRaceCountdown()

        // No A-race, so the countdown key should be cleared
        #expect(defaults.data(forKey: WidgetDataKeys.raceCountdown) == nil)
    }

    @Test("Race countdown includes plan completion percentage")
    func raceCountdownWithPlanCompletion() async {
        let defaults = testDefaults()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [makeRace(priority: .aRace, daysFromNow: 30)]

        let planRepo = MockTrainingPlanRepository()
        let today = Date.now.startOfDay
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: today, type: .tempo, isCompleted: true),
            makeSession(date: today.adding(days: 1), type: .longRun, isCompleted: true),
            makeSession(date: today.adding(days: 2), type: .intervals),
            makeSession(date: today.adding(days: 3), type: .recovery),
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: raceRepo,
            defaults: defaults
        )

        await writer.writeRaceCountdown()

        let data = defaults.data(forKey: WidgetDataKeys.raceCountdown)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetRaceData.self, from: data!)
        #expect(decoded?.name == "Test Ultra")
        // 2 completed out of 4 non-rest sessions = 0.5
        #expect(decoded?.planCompletionPercent == 0.5)
    }

    // MARK: - Fitness Form Timeline Data

    @Test("Fitness form data is written with trend points for sparkline widget")
    func fitnessFormDataWithTrend() async {
        let defaults = testDefaults()
        let fitnessRepo = MockFitnessRepository()

        // Create snapshots over the past week
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -6 + i, to: .now)!
            fitnessRepo.snapshots.append(FitnessSnapshot(
                id: UUID(),
                date: date,
                fitness: 60 + Double(i),
                fatigue: 50 + Double(i),
                form: 10 + Double(i),
                weeklyVolumeKm: 50,
                weeklyElevationGainM: 1500,
                weeklyDuration: 18000,
                acuteToChronicRatio: 1.1,
                monotony: 1.5
            ))
        }

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            fitnessRepository: fitnessRepo,
            defaults: defaults
        )

        await writer.writeFitnessData()

        let data = defaults.data(forKey: WidgetDataKeys.fitnessData)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetFitnessData.self, from: data!)
        #expect(decoded != nil)
        // Latest snapshot values
        #expect(decoded?.form == 16)
        #expect(decoded?.fitness == 66)
        #expect(decoded?.fatigue == 56)
        // Trend should contain all 7 points (within 14-day window)
        #expect(decoded?.trend.count == 7)
        // Trend should be sorted chronologically
        if let trend = decoded?.trend, trend.count >= 2 {
            #expect(trend[0].date < trend[1].date)
        }
    }
}
