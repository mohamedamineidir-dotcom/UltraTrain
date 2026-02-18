import Foundation

protocol NotificationServiceProtocol: AnyObject, Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleTrainingReminder(for session: TrainingSession) async
    func scheduleRaceCountdown(for race: Race) async
    func cancelAllNotifications() async
    func cancelNotifications(withIdentifierPrefix prefix: String) async
    func rescheduleAll(sessions: [TrainingSession], races: [Race]) async
}
