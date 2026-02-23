import Vapor

struct ScheduledJobService: LifecycleHandler {
    func didBoot(_ application: Application) throws {
        application.logger.notice("ScheduledJobService started")
        let app = application
        Task {
            await runLoop(app: app)
        }
    }

    private func runLoop(app: Application) async {
        var lastWeeklySummary: Date = .distantPast
        var lastInactivityCheck: Date = .distantPast
        var lastRaceCountdown: Date = .distantPast
        let inactivityJob = InactivityAlertJob()
        let raceCountdownJob = RaceCountdownJob()

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            let now = Date()
            let calendar = Calendar(identifier: .gregorian)
            let hour = calendar.component(.hour, from: now)

            // Weekly summary: Sunday between 18:00-19:00 UTC
            if calendar.component(.weekday, from: now) == 1,
               hour == 18,
               !calendar.isDate(lastWeeklySummary, inSameDayAs: now) {
                await WeeklySummaryJob.run(app: app)
                lastWeeklySummary = now
            }

            // Inactivity check: daily at 10:00 UTC
            if hour == 10,
               !calendar.isDate(lastInactivityCheck, inSameDayAs: now) {
                await inactivityJob.run(app: app)
                lastInactivityCheck = now
            }

            // Race countdown: daily at 9:00 UTC
            if hour == 9,
               !calendar.isDate(lastRaceCountdown, inSameDayAs: now) {
                await raceCountdownJob.run(app: app)
                lastRaceCountdown = now
            }
        }
    }
}
