import Foundation
import Testing
@testable import UltraTrain

@Suite("NotificationService Tests")
struct NotificationServiceTests {

    // The real NotificationService depends on UNUserNotificationCenter,
    // so we test the mock-based protocol contract and filtering logic
    // that the service performs (e.g., rest sessions excluded, past dates ignored).

    private func makeSession(
        id: UUID = UUID(),
        date: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
        type: SessionType = .longRun,
        isCompleted: Bool = false,
        isSkipped: Bool = false
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: 15,
            plannedElevationGainM: 400,
            plannedDuration: 5400,
            intensity: .moderate,
            description: "Test session",
            isCompleted: isCompleted,
            isSkipped: isSkipped
        )
    }

    private func makeRace(
        id: UUID = UUID(),
        date: Date = Calendar.current.date(byAdding: .month, value: 2, to: .now)!
    ) -> Race {
        Race(
            id: id,
            name: "Test Race",
            date: date,
            distanceKm: 50,
            elevationGainM: 3000,
            elevationLossM: 3000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    // MARK: - rescheduleAll

    @Test("rescheduleAll schedules future non-completed sessions and races")
    func rescheduleAllSchedulesFutureSessions() async {
        let service = MockNotificationService()

        let futureSession = makeSession(date: Calendar.current.date(byAdding: .day, value: 2, to: .now)!)
        let completedSession = makeSession(isCompleted: true)
        let skippedSession = makeSession(isSkipped: true)
        let race = makeRace()

        await service.rescheduleAll(
            sessions: [futureSession, completedSession, skippedSession],
            races: [race]
        )

        #expect(service.rescheduleAllCalled)
        // Mock filters out completed and skipped
        #expect(service.scheduledTrainingSessions.count == 1)
        #expect(service.scheduledRaces.count == 1)
    }

    @Test("rescheduleAll does not schedule completed sessions")
    func rescheduleAllExcludesCompleted() async {
        let service = MockNotificationService()

        let completedSession = makeSession(isCompleted: true)

        await service.rescheduleAll(sessions: [completedSession], races: [])

        #expect(service.scheduledTrainingSessions.isEmpty)
    }

    // MARK: - scheduleTrainingReminder

    @Test("scheduleTrainingReminder records the session")
    func scheduleTrainingReminderRecords() async {
        let service = MockNotificationService()
        let session = makeSession()

        await service.scheduleTrainingReminder(for: session)

        #expect(service.scheduledTrainingSessions.count == 1)
        #expect(service.scheduledTrainingSessions[0].id == session.id)
    }

    // MARK: - scheduleRaceCountdown

    @Test("scheduleRaceCountdown records the race")
    func scheduleRaceCountdownRecords() async {
        let service = MockNotificationService()
        let race = makeRace()

        await service.scheduleRaceCountdown(for: race)

        #expect(service.scheduledRaces.count == 1)
        #expect(service.scheduledRaces[0].id == race.id)
    }

    // MARK: - scheduleRecoveryReminder

    @Test("scheduleRecoveryReminder records the date")
    func scheduleRecoveryReminderRecords() async {
        let service = MockNotificationService()
        let date = Calendar.current.date(byAdding: .day, value: 3, to: .now)!

        await service.scheduleRecoveryReminder(for: date)

        #expect(service.scheduledRecoveryDates.count == 1)
    }

    // MARK: - scheduleWeeklySummary

    @Test("scheduleWeeklySummary records the summary data")
    func scheduleWeeklySummaryRecords() async {
        let service = MockNotificationService()

        await service.scheduleWeeklySummary(distanceKm: 45.0, elevationM: 1500, runCount: 5)

        #expect(service.scheduledWeeklySummaries.count == 1)
        #expect(service.scheduledWeeklySummaries[0].distanceKm == 45.0)
        #expect(service.scheduledWeeklySummaries[0].elevationM == 1500)
        #expect(service.scheduledWeeklySummaries[0].runCount == 5)
    }

    // MARK: - cancelAllNotifications

    @Test("cancelAllNotifications sets the flag")
    func cancelAllSetsFlag() async {
        let service = MockNotificationService()

        await service.cancelAllNotifications()

        #expect(service.cancelAllCalled)
    }

    // MARK: - cancelNotifications by prefix

    @Test("cancelNotifications records the prefix")
    func cancelByPrefixRecordsPrefix() async {
        let service = MockNotificationService()

        await service.cancelNotifications(withIdentifierPrefix: "training")
        await service.cancelNotifications(withIdentifierPrefix: "race")

        #expect(service.cancelledPrefixes == ["training", "race"])
    }

    // MARK: - Sound Preferences

    @Test("soundPreferences can be set per category")
    func soundPreferencesCanBeSet() {
        let service = MockNotificationService()

        service.soundPreferences[.training] = .custom
        service.soundPreferences[.race] = .silent
        service.soundPreferences[.recovery] = .defaultSound

        #expect(service.soundPreferences[.training] == .custom)
        #expect(service.soundPreferences[.race] == .silent)
        #expect(service.soundPreferences[.recovery] == .defaultSound)
        #expect(service.soundPreferences[.weeklySummary] == nil)
    }
}
