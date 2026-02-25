import Foundation
import os

// MARK: - Notification Toggles & Quiet Hours

extension SettingsViewModel {

    func updateTrainingReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.trainingRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                if let plan = try await planRepository.getActivePlan() {
                    let sessions = plan.weeks.flatMap(\.sessions)
                    let races = try await raceRepository.getRaces()
                    await notificationService.rescheduleAll(sessions: sessions, races: races)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "training-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update training reminders: \(error)")
        }
    }

    func updateNutritionReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.nutritionRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update nutrition reminders: \(error)")
        }
    }

    func updateNutritionAlertSound(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.nutritionAlertSoundEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update nutrition alert sound: \(error)")
        }
    }

    func updateRaceCountdown(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.raceCountdownEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                let races = try await raceRepository.getRaces()
                for race in races {
                    await notificationService.scheduleRaceCountdown(for: race)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "race-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update race countdown: \(error)")
        }
    }

    func updateRecoveryReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.recoveryRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                if let plan = try await planRepository.getActivePlan() {
                    let sessions = plan.weeks.flatMap(\.sessions)
                    let races = try await raceRepository.getRaces()
                    await notificationService.rescheduleAll(sessions: sessions, races: races)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "recovery-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update recovery reminders: \(error)")
        }
    }

    func updateWeeklySummary(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.weeklySummaryEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "weekly-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update weekly summary: \(error)")
        }
    }

    // MARK: - Nutrition Interval Settings

    func updateHydrationInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.hydrationIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update hydration interval: \(error)")
        }
    }

    func updateFuelInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.fuelIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update fuel interval: \(error)")
        }
    }

    func updateElectrolyteInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.electrolyteIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update electrolyte interval: \(error)")
        }
    }

    func updateSmartReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.smartRemindersEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update smart reminders: \(error)")
        }
    }

    // MARK: - Quiet Hours

    func updateQuietHours(enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.quietHoursEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours: \(error)")
        }
    }

    func updateQuietHoursStart(_ hour: Int) async {
        guard var settings = appSettings else { return }
        settings.quietHoursStart = hour
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours start: \(error)")
        }
    }

    func updateQuietHoursEnd(_ hour: Int) async {
        guard var settings = appSettings else { return }
        settings.quietHoursEnd = hour
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours end: \(error)")
        }
    }
}
