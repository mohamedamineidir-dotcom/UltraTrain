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

    // MARK: - Categories

    func registerNotificationCategories() async {
        let viewSession = UNNotificationAction(identifier: "viewSession", title: "View Session")
        let skipSession = UNNotificationAction(identifier: "skipSession", title: "Skip Session")
        let viewRace = UNNotificationAction(identifier: "viewRace", title: "View Race")
        let viewProgress = UNNotificationAction(identifier: "viewProgress", title: "View Progress")
        let dismiss = UNNotificationAction(identifier: "dismiss", title: "Dismiss")

        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "training", actions: [viewSession, skipSession], intentIdentifiers: []),
            UNNotificationCategory(identifier: "race", actions: [viewRace], intentIdentifiers: []),
            UNNotificationCategory(identifier: "recovery", actions: [dismiss], intentIdentifiers: []),
            UNNotificationCategory(identifier: "weeklySummary", actions: [viewProgress], intentIdentifiers: []),
        ]
        center.setNotificationCategories(categories)
        Logger.notification.info("Registered notification categories")
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
        content.body = NotificationContentBuilder.trainingReminderBody(session)
        content.sound = .default
        content.categoryIdentifier = "training"
        content.userInfo = ["sessionId": session.id.uuidString]

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
        let daysBeforeRace = [56, 49, 42, 35, 28, 21, 14, 7, 6, 5, 4, 3, 2, 1]

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
            content.body = NotificationContentBuilder.raceCountdownBody(raceName: race.name, daysRemaining: days)
            content.sound = .default
            content.categoryIdentifier = "race"
            content.userInfo = ["raceId": race.id.uuidString]

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

    // MARK: - Recovery Reminder

    func scheduleRecoveryReminder(for date: Date) async {
        guard date > Date.now else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Rest Day"
        content.body = NotificationContentBuilder.recoveryReminderBody()
        content.sound = .default
        content.categoryIdentifier = "recovery"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let dateStr = ISO8601DateFormatter().string(from: date)
        let identifier = "recovery-\(dateStr)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            Logger.notification.info("Scheduled recovery reminder: \(identifier)")
        } catch {
            Logger.notification.error("Failed to schedule recovery reminder: \(error)")
        }
    }

    // MARK: - Weekly Summary

    func scheduleWeeklySummary(distanceKm: Double, elevationM: Double, runCount: Int) async {
        let calendar = Calendar.current
        let now = Date.now
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0

        guard let nextSunday = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else {
            return
        }

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextSunday)

        let content = UNMutableNotificationContent()
        content.title = "Weekly Training Summary"
        content.body = NotificationContentBuilder.weeklySummaryBody(
            distanceKm: distanceKm,
            elevationM: elevationM,
            runCount: runCount
        )
        content.sound = .default
        content.categoryIdentifier = "weeklySummary"

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let dateStr = ISO8601DateFormatter().string(from: nextSunday)
        let identifier = "summary-\(dateStr)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            Logger.notification.info("Scheduled weekly summary: \(identifier)")
        } catch {
            Logger.notification.error("Failed to schedule weekly summary: \(error)")
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

        let restDays = sessions.filter { $0.type == .rest && $0.date > Date.now }
        for session in restDays {
            await scheduleRecoveryReminder(for: session.date)
        }

        Logger.notification.info("Rescheduled all: \(futureSessions.count) sessions, \(races.count) races")
    }
}
