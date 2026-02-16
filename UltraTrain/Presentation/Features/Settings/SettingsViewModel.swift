import Foundation
import os

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol

    // MARK: - State

    var athlete: Athlete?
    var appSettings: AppSettings?
    var isLoading = false
    var error: String?
    var showingClearDataConfirmation = false
    var didClearData = false
    var healthKitRestingHR: Int?
    var healthKitMaxHR: Int?
    var isRequestingHealthKit = false
    var showHealthKitExplanation = false

    var healthKitStatus: HealthKitAuthStatus {
        healthKitService.authorizationStatus
    }

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol
    ) {
        self.athleteRepository = athleteRepository
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            appSettings = try await appSettingsRepository.getSettings()

            if appSettings == nil {
                let defaults = AppSettings(
                    id: UUID(),
                    trainingRemindersEnabled: true,
                    nutritionRemindersEnabled: true,
                    autoPauseEnabled: true,
                    nutritionAlertSoundEnabled: true
                )
                try await appSettingsRepository.saveSettings(defaults)
                appSettings = defaults
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to load settings: \(error)")
        }

        if healthKitStatus == .authorized {
            await fetchHealthKitData()
        }

        isLoading = false
    }

    // MARK: - Unit Preference

    func updateUnitPreference(_ unit: UnitPreference) async {
        guard var athlete else { return }
        athlete.preferredUnit = unit

        do {
            try await athleteRepository.updateAthlete(athlete)
            self.athlete = athlete
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update unit preference: \(error)")
        }
    }

    // MARK: - Notification Toggles

    func updateTrainingReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.trainingRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
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

    // MARK: - HealthKit

    func requestHealthKitAuthorization() async {
        isRequestingHealthKit = true
        do {
            try await healthKitService.requestAuthorization()
            await fetchHealthKitData()
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to request HealthKit authorization: \(error)")
        }
        isRequestingHealthKit = false
    }

    func fetchHealthKitData() async {
        do {
            healthKitRestingHR = try await healthKitService.fetchRestingHeartRate()
            healthKitMaxHR = try await healthKitService.fetchMaxHeartRate()
        } catch {
            Logger.settings.error("Failed to fetch HealthKit data: \(error)")
        }
    }

    func updateAthleteWithHealthKitData() async {
        guard var athlete else { return }
        var changed = false

        if let rhr = healthKitRestingHR {
            athlete.restingHeartRate = rhr
            changed = true
        }
        if let mhr = healthKitMaxHR {
            athlete.maxHeartRate = mhr
            changed = true
        }

        guard changed else { return }
        do {
            try await athleteRepository.updateAthlete(athlete)
            self.athlete = athlete
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update athlete with HealthKit data: \(error)")
        }
    }

    // MARK: - Auto Pause

    func updateAutoPause(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.autoPauseEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update auto-pause setting: \(error)")
        }
    }

    // MARK: - Clear Data

    func clearAllData() async {
        do {
            try await clearAllDataUseCase.execute()
            athlete = nil
            appSettings = nil
            didClearData = true
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to clear all data: \(error)")
        }
    }
}
