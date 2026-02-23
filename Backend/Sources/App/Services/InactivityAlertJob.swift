import Vapor
import Fluent

actor InactivityAlertJob {
    private var lastNudgeSent: [UUID: Date] = [:]

    func run(app: Application) async {
        do {
            let users = try await UserModel.query(on: app.db)
                .filter(\.$deviceToken != nil)
                .all()

            let pushService = PushNotificationService(app: app)
            let now = Date()
            let calendar = Calendar.current

            for user in users {
                guard let token = user.deviceToken, let userId = user.id else { continue }

                // Skip if we nudged this user in the last 7 days
                if let lastNudge = lastNudgeSent[userId],
                   calendar.dateComponents([.day], from: lastNudge, to: now).day ?? 0 < 7 {
                    continue
                }

                let latestRun = try await RunModel.query(on: app.db)
                    .filter(\.$user.$id == userId)
                    .sort(\.$date, .descending)
                    .first()

                let daysSinceLastRun: Int
                if let lastRunDate = latestRun?.date {
                    daysSinceLastRun = calendar.dateComponents([.day], from: lastRunDate, to: now).day ?? 0
                } else {
                    continue // No runs at all, skip
                }

                guard daysSinceLastRun >= 5 else { continue }

                do {
                    try await pushService.sendInactivityNudge(to: token, daysSinceLastRun: daysSinceLastRun)
                    lastNudgeSent[userId] = now
                } catch {
                    app.logger.warning("Failed to send inactivity nudge to user \(userId): \(error)")
                }
            }

            app.logger.info("InactivityAlertJob completed for \(users.count) users")
        } catch {
            app.logger.error("InactivityAlertJob failed: \(error)")
        }
    }
}
