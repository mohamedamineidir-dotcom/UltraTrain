import Vapor
import Fluent

actor RaceCountdownJob {
    private var lastSentMilestone: [UUID: Int] = [:]

    private static let milestones = [30, 14, 7, 3, 1]

    func run(app: Application) async {
        do {
            let users = try await UserModel.query(on: app.db)
                .filter(\.$deviceToken != nil)
                .all()

            let pushService = PushNotificationService(app: app)
            let now = Date()
            let calendar = Calendar(identifier: .gregorian)

            for user in users {
                guard let token = user.deviceToken, let userId = user.id else { continue }

                guard let plan = try await TrainingPlanModel.query(on: app.db)
                    .filter(\.$user.$id == userId)
                    .first() else { continue }

                let daysRemaining = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: plan.targetRaceDate)).day ?? 0

                guard daysRemaining > 0 else { continue }

                guard let milestone = Self.milestones.first(where: { $0 == daysRemaining }) else { continue }

                // Skip if we already sent this milestone for this user
                if lastSentMilestone[userId] == milestone { continue }

                do {
                    try await pushService.sendRaceCountdown(
                        to: token,
                        raceName: plan.targetRaceName,
                        daysRemaining: daysRemaining
                    )
                    lastSentMilestone[userId] = milestone
                } catch {
                    app.logger.warning("Failed to send race countdown to user \(userId): \(error)")
                }
            }

            app.logger.info("RaceCountdownJob completed for \(users.count) users")
        } catch {
            app.logger.error("RaceCountdownJob failed: \(error)")
        }
    }
}
