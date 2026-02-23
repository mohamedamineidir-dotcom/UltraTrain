import Vapor
import VaporAPNS
import APNSCore

struct PushNotificationService {
    let app: Application

    func sendTrainingReminder(to deviceToken: String, sessionTitle: String) async throws {
        let alert = APNSAlertNotification(
            alert: .init(title: .raw("Training Reminder"), body: .raw("Time for: \(sessionTitle)")),
            expiration: .immediately,
            priority: .immediately,
            topic: "com.ultratrain.app",
            category: "training"
        )
        try await app.apns.client.sendAlertNotification(alert, deviceToken: deviceToken)
    }

    func sendSyncAvailable(to deviceToken: String) async throws {
        let alert = APNSAlertNotification(
            alert: .init(title: .raw("Sync Available"), body: .raw("New training data is ready to sync.")),
            expiration: .immediately,
            priority: .consideringDevicePower,
            topic: "com.ultratrain.app",
            category: "sync_available"
        )
        try await app.apns.client.sendAlertNotification(alert, deviceToken: deviceToken)
    }

    func sendWeeklySummary(to deviceToken: String, distanceKm: Double, elevationM: Double, runCount: Int) async throws {
        let body = String(format: "This week: %.1f km, %.0f m D+ across %d run%@. Keep it up!",
                          distanceKm, elevationM, runCount, runCount == 1 ? "" : "s")
        let alert = APNSAlertNotification(
            alert: .init(title: .raw("Weekly Training Summary"), body: .raw(body)),
            expiration: .immediately,
            priority: .consideringDevicePower,
            topic: "com.ultratrain.app",
            category: "weeklySummary"
        )
        try await app.apns.client.sendAlertNotification(alert, deviceToken: deviceToken)
    }

    func sendInactivityNudge(to deviceToken: String, daysSinceLastRun: Int) async throws {
        let body = "It's been \(daysSinceLastRun) days since your last run. A short recovery run can do wonders!"
        let alert = APNSAlertNotification(
            alert: .init(title: .raw("Time to Run?"), body: .raw(body)),
            expiration: .immediately,
            priority: .consideringDevicePower,
            topic: "com.ultratrain.app",
            category: "inactivity"
        )
        try await app.apns.client.sendAlertNotification(alert, deviceToken: deviceToken)
    }

    func sendRaceCountdown(to deviceToken: String, raceName: String, daysRemaining: Int) async throws {
        let body = daysRemaining == 1
            ? "\(raceName) is tomorrow! You've got this."
            : "\(daysRemaining) days until \(raceName). Stay focused."
        let alert = APNSAlertNotification(
            alert: .init(title: .raw("Race Countdown"), body: .raw(body)),
            expiration: .immediately,
            priority: .immediately,
            topic: "com.ultratrain.app",
            category: "race"
        )
        try await app.apns.client.sendAlertNotification(alert, deviceToken: deviceToken)
    }
}
