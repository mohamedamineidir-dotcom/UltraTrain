import Foundation
import SwiftData
import os

// @unchecked Sendable: thread-safe via ModelContainer (new context per call)
final class LocalAppSettingsRepository: AppSettingsRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getSettings() async throws -> AppSettings? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AppSettingsSwiftDataModel>()
        let results = try context.fetch(descriptor)

        guard let model = results.first else { return nil }
        return AppSettingsSwiftDataMapper.toDomain(model)
    }

    func saveSettings(_ settings: AppSettings) async throws {
        let context = ModelContext(modelContainer)
        let model = AppSettingsSwiftDataMapper.toSwiftData(settings)
        context.insert(model)
        try context.save()
        Logger.persistence.info("App settings saved")
    }

    func updateSettings(_ settings: AppSettings) async throws {
        let context = ModelContext(modelContainer)
        let targetId = settings.id
        var descriptor = FetchDescriptor<AppSettingsSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.settingsNotFound
        }

        existing.trainingRemindersEnabled = settings.trainingRemindersEnabled
        existing.nutritionRemindersEnabled = settings.nutritionRemindersEnabled
        existing.autoPauseEnabled = settings.autoPauseEnabled
        existing.nutritionAlertSoundEnabled = settings.nutritionAlertSoundEnabled
        existing.stravaAutoUploadEnabled = settings.stravaAutoUploadEnabled
        existing.stravaConnected = settings.stravaConnected
        existing.raceCountdownEnabled = settings.raceCountdownEnabled
        existing.biometricLockEnabled = settings.biometricLockEnabled
        existing.hydrationIntervalSeconds = settings.hydrationIntervalSeconds
        existing.fuelIntervalSeconds = settings.fuelIntervalSeconds
        existing.electrolyteIntervalSeconds = settings.electrolyteIntervalSeconds
        existing.smartRemindersEnabled = settings.smartRemindersEnabled
        existing.saveToHealthEnabled = settings.saveToHealthEnabled
        existing.healthKitAutoImportEnabled = settings.healthKitAutoImportEnabled
        existing.pacingAlertsEnabled = settings.pacingAlertsEnabled
        existing.recoveryRemindersEnabled = settings.recoveryRemindersEnabled
        existing.weeklySummaryEnabled = settings.weeklySummaryEnabled
        existing.appearanceModeRaw = settings.appearanceMode.rawValue
        existing.quietHoursEnabled = settings.quietHoursEnabled
        existing.quietHoursStart = settings.quietHoursStart
        existing.quietHoursEnd = settings.quietHoursEnd
        existing.dataRetentionMonths = settings.dataRetentionMonths
        do {
            existing.voiceCoachingConfigData = try JSONEncoder().encode(settings.voiceCoachingConfig)
        } catch {
            Logger.persistence.warning("Failed to encode voiceCoachingConfig: \(error)")
        }
        do {
            existing.safetyConfigData = try JSONEncoder().encode(settings.safetyConfig)
        } catch {
            Logger.persistence.warning("Failed to encode safetyConfig: \(error)")
        }
        do {
            existing.notificationSoundPreferencesData = try JSONEncoder().encode(settings.notificationSoundPreferences)
        } catch {
            Logger.persistence.warning("Failed to encode notificationSoundPreferences: \(error)")
        }

        try context.save()
        Logger.persistence.info("App settings updated")
    }
}
