import Foundation
import Testing
@testable import UltraTrain

@Suite("Widget Data Writer Tests")
struct WidgetDataWriterTests {

    private func testDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.widgetwriter.\(UUID().uuidString)")!
    }

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeSession(
        date: Date = .now,
        type: SessionType = .longRun,
        isCompleted: Bool = false
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
            isSkipped: false,
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

    private func makeRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: 15,
            elevationGainM: 400,
            elevationLossM: 380,
            duration: 4500,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 300,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    // MARK: - Write Next Session

    @Test("Write next session with active plan")
    func writeNextSession() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: tomorrow, type: .longRun)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeNextSession()

        let data = defaults.data(forKey: WidgetDataKeys.nextSession)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetSessionData.self, from: data!)
        #expect(decoded?.sessionType == "longRun")
        #expect(decoded?.displayName == "Long Run")
        #expect(decoded?.sessionIcon == "figure.run")
    }

    @Test("Write next session clears when no plan")
    func writeNextSessionNoPlan() async {
        let defaults = testDefaults()
        // Pre-populate to verify it gets cleared
        defaults.set(Data(), forKey: WidgetDataKeys.nextSession)

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeNextSession()

        #expect(defaults.data(forKey: WidgetDataKeys.nextSession) == nil)
    }

    @Test("Write next session skips completed sessions")
    func writeNextSessionSkipsCompleted() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: tomorrow, type: .tempo, isCompleted: true),
            makeSession(date: dayAfter, type: .longRun)
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
        #expect(decoded?.sessionType == "longRun")
    }

    // MARK: - Write Race Countdown

    @Test("Write race countdown with A-race")
    func writeRaceCountdown() async {
        let defaults = testDefaults()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [makeRace()]

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: raceRepo,
            defaults: defaults
        )

        await writer.writeRaceCountdown()

        let data = defaults.data(forKey: WidgetDataKeys.raceCountdown)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetRaceData.self, from: data!)
        #expect(decoded?.name == "Test Ultra")
        #expect(decoded?.distanceKm == 100)
    }

    @Test("Write race countdown clears when no A-race")
    func writeRaceCountdownNoRace() async {
        let defaults = testDefaults()
        defaults.set(Data(), forKey: WidgetDataKeys.raceCountdown)

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeRaceCountdown()

        #expect(defaults.data(forKey: WidgetDataKeys.raceCountdown) == nil)
    }

    // MARK: - Write Weekly Progress

    @Test("Write weekly progress with active plan")
    func writeWeeklyProgress() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let today = Date.now.startOfDay
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: today, type: .tempo, isCompleted: true),
            makeSession(date: today.adding(days: 1), type: .longRun)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeWeeklyProgress()

        let data = defaults.data(forKey: WidgetDataKeys.weeklyProgress)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetWeeklyProgressData.self, from: data!)
        #expect(decoded?.weekNumber == 5)
        #expect(decoded?.phase == "build")
        #expect(decoded?.actualDistanceKm == 20) // One completed session
    }

    @Test("Write weekly progress clears when no plan")
    func writeWeeklyProgressNoPlan() async {
        let defaults = testDefaults()
        defaults.set(Data(), forKey: WidgetDataKeys.weeklyProgress)

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeWeeklyProgress()

        #expect(defaults.data(forKey: WidgetDataKeys.weeklyProgress) == nil)
    }

    // MARK: - Write Last Run

    @Test("Write last run with recent runs")
    func writeLastRun() async {
        let defaults = testDefaults()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: runRepo,
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeLastRun()

        let data = defaults.data(forKey: WidgetDataKeys.lastRun)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetLastRunData.self, from: data!)
        #expect(decoded?.distanceKm == 15)
        #expect(decoded?.averageHeartRate == 145)
    }

    @Test("Write last run clears when no runs")
    func writeLastRunNoRuns() async {
        let defaults = testDefaults()
        defaults.set(Data(), forKey: WidgetDataKeys.lastRun)

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeLastRun()

        #expect(defaults.data(forKey: WidgetDataKeys.lastRun) == nil)
    }

    // MARK: - Write All

    @Test("Write all writes all 4 keys")
    func writeAll() async {
        let defaults = testDefaults()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(date: tomorrow, type: .longRun)
        ])
        let raceRepo = MockRaceRepository()
        raceRepo.races = [makeRace()]
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: runRepo,
            raceRepository: raceRepo,
            defaults: defaults
        )

        await writer.writeAll()

        #expect(defaults.data(forKey: WidgetDataKeys.nextSession) != nil)
        #expect(defaults.data(forKey: WidgetDataKeys.raceCountdown) != nil)
        #expect(defaults.data(forKey: WidgetDataKeys.weeklyProgress) != nil)
        #expect(defaults.data(forKey: WidgetDataKeys.lastRun) != nil)
    }
}
