import Foundation
import UserNotifications
import os

final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        Logger.notification.info("Notification authorization granted: \(granted)")
        return granted
    }

    // MARK: - Training Reminders

    func scheduleTrainingReminder(for session: TrainingSession) async {
        guard session.date > Date.now else { return }
        guard session.type != .rest else { return }

        let calendar = Calendar.current
        guard let eveningBefore = calendar.date(byAdding: .day, value: -1, to: session.date) else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: eveningBefore)
        components.hour = 20
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Tomorrow's Training"
        content.body = buildTrainingReminderBody(session)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "training-\(session.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            Logger.notification.info("Scheduled training reminder: \(identifier)")
        } catch {
            Logger.notification.error("Failed to schedule training reminder: \(error)")
        }
    }

    // MARK: - Race Countdown

    func scheduleRaceCountdown(for race: Race) async {
        let daysBeforeRace = [7, 3, 1]

        for days in daysBeforeRace {
            guard let reminderDate = Calendar.current.date(byAdding: .day, value: -days, to: race.date) else {
                continue
            }
            guard reminderDate > Date.now else { continue }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
            components.hour = 9
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Race Countdown"
            content.body = "Your race \(race.name) is in \(days) day\(days == 1 ? "" : "s")!"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "race-\(race.id.uuidString)-\(days)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                Logger.notification.info("Scheduled race countdown: \(identifier)")
            } catch {
                Logger.notification.error("Failed to schedule race countdown: \(error)")
            }
        }
    }

    // MARK: - Cancel

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        Logger.notification.info("All notifications cancelled")
    }

    func cancelNotifications(withIdentifierPrefix prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let idsToRemove = pending.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
        guard !idsToRemove.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        Logger.notification.info("Cancelled \(idsToRemove.count) notifications with prefix '\(prefix)'")
    }

    // MARK: - Reschedule All

    func rescheduleAll(sessions: [TrainingSession], races: [Race]) async {
        await cancelAllNotifications()

        let futureSessions = sessions.filter { !$0.isCompleted && !$0.isSkipped && $0.date > Date.now }
        for session in futureSessions {
            await scheduleTrainingReminder(for: session)
        }

        for race in races {
            await scheduleRaceCountdown(for: race)
        }

        Logger.notification.info("Rescheduled all: \(futureSessions.count) sessions, \(races.count) races")
    }

    // MARK: - Helpers

    private func buildTrainingReminderBody(_ session: TrainingSession) -> String {
        var parts: [String] = []

        let typeName: String = switch session.type {
        case .longRun: "Long Run"
        case .tempo: "Tempo"
        case .intervals: "Intervals"
        case .verticalGain: "Vertical Gain"
        case .backToBack: "Back-to-Back"
        case .recovery: "Recovery Run"
        case .crossTraining: "Cross Training"
        case .rest: "Rest Day"
        }
        parts.append(typeName)

        if session.plannedDistanceKm > 0 {
            parts.append(String(format: "%.1f km", session.plannedDistanceKm))
        }
        if session.plannedElevationGainM > 0 {
            parts.append(String(format: "%.0f m D+", session.plannedElevationGainM))
        }

        return "Tomorrow: " + parts.joined(separator: " — ")
    }
}
