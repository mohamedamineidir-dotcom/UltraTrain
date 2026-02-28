import Foundation

protocol NotificationServiceProtocol: AnyObject, Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleTrainingReminder(for session: TrainingSession) async
    func scheduleRaceCountdown(for race: Race) async
    func cancelAllNotifications() async
    func cancelNotifications(withIdentifierPrefix prefix: String) async
    func rescheduleAll(sessions: [TrainingSession], races: [Race]) async
    func scheduleRecoveryReminder(for date: Date) async
    func scheduleWeeklySummary(distanceKm: Double, elevationM: Double, runCount: Int) async
    func registerNotificationCategories() async
    func scheduleInactivityReminder(lastRunDate: Date) async
}
