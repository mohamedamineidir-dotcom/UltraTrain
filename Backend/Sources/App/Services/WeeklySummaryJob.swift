import Vapor
import Fluent

enum WeeklySummaryJob {
    static func run(app: Application) async {
        do {
            let users = try await UserModel.query(on: app.db)
                .filter(\.$deviceToken != nil)
                .all()

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let pushService = PushNotificationService(app: app)

            for user in users {
                guard let token = user.deviceToken, let userId = user.id else { continue }

                let runs = try await RunModel.query(on: app.db)
                    .filter(\.$user.$id == userId)
                    .filter(\.$date >= sevenDaysAgo)
                    .all()

                guard !runs.isEmpty else { continue }

                let totalKm = runs.reduce(0.0) { $0 + $1.distanceKm }
                let totalElev = runs.reduce(0.0) { $0 + $1.elevationGainM }

                do {
                    try await pushService.sendWeeklySummary(
                        to: token,
                        distanceKm: totalKm,
                        elevationM: totalElev,
                        runCount: runs.count
                    )
                } catch {
                    app.logger.warning("Failed to send weekly summary to user \(userId): \(error)")
                }
            }

            app.logger.info("WeeklySummaryJob completed for \(users.count) users")
        } catch {
            app.logger.error("WeeklySummaryJob failed: \(error)")
        }
    }
}
