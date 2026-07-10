import Vapor

final class ScheduledJobService: LifecycleHandler {
    // didBoot and shutdown are called sequentially by Vapor's lifecycle —
    // never concurrently — so nonisolated(unsafe) is safe here.
    nonisolated(unsafe) private var loopTask: Task<Void, Never>?

    func didBoot(_ application: Application) throws {
        application.logger.notice("ScheduledJobService started")
        let app = application
        loopTask = Task { [weak self] in
            await self?.runLoop(app: app)
        }
    }

    func shutdown(_ application: Application) {
        loopTask?.cancel()
        application.logger.notice("ScheduledJobService: loop cancelled for shutdown")
    }

    private func runLoop(app: Application) async {
        var lastWeeklySummary: Date = .distantPast
        var lastInactivityCheck: Date = .distantPast
        var lastRaceCountdown: Date = .distantPast
        let inactivityJob = InactivityAlertJob()
        let raceCountdownJob = RaceCountdownJob()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                break  // Task cancelled — exit cleanly
            }

            let now = Date()
            let calendar = Calendar(identifier: .gregorian)
            let hour = calendar.component(.hour, from: now)

            if calendar.component(.weekday, from: now) == 1,
               hour == 18,
               !calendar.isDate(lastWeeklySummary, inSameDayAs: now) {
                await WeeklySummaryJob.run(app: app)
                lastWeeklySummary = now
            }

            if hour == 10,
               !calendar.isDate(lastInactivityCheck, inSameDayAs: now) {
                await inactivityJob.run(app: app)
                lastInactivityCheck = now
            }

            if hour == 9,
               !calendar.isDate(lastRaceCountdown, inSameDayAs: now) {
                await raceCountdownJob.run(app: app)
                lastRaceCountdown = now
            }
        }

        app.logger.notice("ScheduledJobService loop exited")
    }
}
