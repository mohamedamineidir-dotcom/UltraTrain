import Foundation
@testable import UltraTrain

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    var authorizationGranted = true
    var shouldThrow = false
    var requestAuthorizationCalled = false
    var scheduledTrainingSessions: [TrainingSession] = []
    var scheduledRaces: [Race] = []
    var cancelAllCalled = false
    var cancelledPrefixes: [String] = []
    var rescheduleAllCalled = false
    var registerCategoriesCalled = false
    var scheduledRecoveryDates: [Date] = []
    var scheduledWeeklySummaries: [(distanceKm: Double, elevationM: Double, runCount: Int)] = []

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCalled = true
        if shouldThrow { throw DomainError.notificationDenied }
        return authorizationGranted
    }

    func scheduleTrainingReminder(for session: TrainingSession) async {
        scheduledTrainingSessions.append(session)
    }

    func scheduleRaceCountdown(for race: Race) async {
        scheduledRaces.append(race)
    }

    func cancelAllNotifications() async {
        cancelAllCalled = true
    }

    func cancelNotifications(withIdentifierPrefix prefix: String) async {
        cancelledPrefixes.append(prefix)
    }

    func rescheduleAll(sessions: [TrainingSession], races: [Race]) async {
        rescheduleAllCalled = true
        scheduledTrainingSessions = sessions.filter { !$0.isCompleted && !$0.isSkipped }
        scheduledRaces = races
    }

    func scheduleRecoveryReminder(for date: Date) async {
        scheduledRecoveryDates.append(date)
    }

    func scheduleWeeklySummary(distanceKm: Double, elevationM: Double, runCount: Int) async {
        scheduledWeeklySummaries.append((distanceKm: distanceKm, elevationM: elevationM, runCount: runCount))
    }

    func registerNotificationCategories() async {
        registerCategoriesCalled = true
    }
}
