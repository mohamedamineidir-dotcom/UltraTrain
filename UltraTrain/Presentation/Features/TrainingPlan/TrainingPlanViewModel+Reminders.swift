import Foundation
import os

// MARK: - Scheduled Reminders Sync
//
// #27: keeps the in-plan training reminders (night-before pre-session
// notifications, race countdowns, rest-day reminders) in sync with the
// current plan. Settings already owns the on/off toggles; this layer
// is about making sure a plan mutation (regenerate, swap, reschedule,
// skip, link-to-run) doesn't leave reminders pointing at stale data.
//
// All calls are nil-safe: if the notificationService or
// appSettingsRepository weren't injected, the refresh is a no-op.
// If the athlete has the training-reminders toggle OFF, we also
// no-op so we don't resurrect notifications behind their back.

extension TrainingPlanViewModel {

    func refreshScheduledReminders() {
        guard let notificationService,
              let appSettingsRepository,
              let plan else { return }
        let sessions = plan.weeks.flatMap(\.sessions)
        let currentRaces = races
        Task {
            do {
                guard let settings = try await appSettingsRepository.getSettings() else {
                    return
                }
                // Only mirror the state the athlete opted into. If they
                // haven't turned training reminders on, we don't start
                // silently scheduling — same goes for the other toggles
                // which NotificationService already respects via its
                // identifier-prefix cleanup.
                guard settings.trainingRemindersEnabled
                        || settings.recoveryRemindersEnabled
                        || settings.raceCountdownEnabled else {
                    return
                }
                await notificationService.rescheduleAll(sessions: sessions, races: currentRaces)
                Logger.training.info("Training reminders refreshed: \(sessions.count) sessions, \(currentRaces.count) races")
            } catch {
                Logger.training.error("Failed to refresh reminders: \(error)")
            }
        }
    }
}
