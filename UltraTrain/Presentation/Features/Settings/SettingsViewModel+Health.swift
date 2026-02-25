import Foundation
import os

// MARK: - Biometric Lock & HealthKit

extension SettingsViewModel {

    // MARK: - Biometric Lock

    func updateBiometricLock(_ enabled: Bool) async {
        guard var settings = appSettings else { return }

        if enabled {
            do {
                let success = try await biometricAuthService.authenticate(
                    reason: "Verify your identity to enable app lock"
                )
                guard success else {
                    self.error = "Authentication failed. Please try again."
                    return
                }
            } catch {
                self.error = error.localizedDescription
                Logger.biometric.error("Failed to verify biometrics: \(error)")
                return
            }
        }

        settings.biometricLockEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update biometric lock: \(error)")
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
            healthKitBodyWeight = try await healthKitService.fetchBodyWeight()
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
        if let weight = healthKitBodyWeight {
            athlete.weightKg = weight
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

    func updateSaveToHealth(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.saveToHealthEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update save-to-health setting: \(error)")
        }
    }

    // MARK: - HealthKit Import

    func updateHealthKitAutoImport(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.healthKitAutoImportEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
            if enabled {
                await importFromHealthKit()
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update HealthKit auto-import: \(error)")
        }
    }

    func importFromHealthKit() async {
        guard let athlete, let importService = healthKitImportService else { return }
        isImportingFromHealth = true
        do {
            lastImportResult = try await importService.importNewWorkouts(athleteId: athlete.id)
        } catch {
            Logger.healthKit.error("HealthKit import failed: \(error)")
        }
        isImportingFromHealth = false
    }
}
