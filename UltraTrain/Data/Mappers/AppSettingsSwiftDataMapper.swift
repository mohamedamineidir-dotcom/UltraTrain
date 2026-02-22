import Foundation

enum AppSettingsSwiftDataMapper {
    static func toDomain(_ model: AppSettingsSwiftDataModel) -> AppSettings {
        let voiceCoachingConfig: VoiceCoachingConfig
        if let data = model.voiceCoachingConfigData {
            voiceCoachingConfig = (try? JSONDecoder().decode(VoiceCoachingConfig.self, from: data)) ?? VoiceCoachingConfig()
        } else {
            voiceCoachingConfig = VoiceCoachingConfig()
        }

        return AppSettings(
            id: model.id,
            trainingRemindersEnabled: model.trainingRemindersEnabled,
            nutritionRemindersEnabled: model.nutritionRemindersEnabled,
            autoPauseEnabled: model.autoPauseEnabled,
            nutritionAlertSoundEnabled: model.nutritionAlertSoundEnabled,
            stravaAutoUploadEnabled: model.stravaAutoUploadEnabled,
            stravaConnected: model.stravaConnected,
            raceCountdownEnabled: model.raceCountdownEnabled,
            biometricLockEnabled: model.biometricLockEnabled,
            hydrationIntervalSeconds: model.hydrationIntervalSeconds,
            fuelIntervalSeconds: model.fuelIntervalSeconds,
            electrolyteIntervalSeconds: model.electrolyteIntervalSeconds,
            smartRemindersEnabled: model.smartRemindersEnabled,
            saveToHealthEnabled: model.saveToHealthEnabled,
            healthKitAutoImportEnabled: model.healthKitAutoImportEnabled,
            pacingAlertsEnabled: model.pacingAlertsEnabled,
            recoveryRemindersEnabled: model.recoveryRemindersEnabled,
            weeklySummaryEnabled: model.weeklySummaryEnabled,
            voiceCoachingConfig: voiceCoachingConfig
        )
    }

    static func toSwiftData(_ settings: AppSettings) -> AppSettingsSwiftDataModel {
        let model = AppSettingsSwiftDataModel(
            id: settings.id,
            trainingRemindersEnabled: settings.trainingRemindersEnabled,
            nutritionRemindersEnabled: settings.nutritionRemindersEnabled,
            autoPauseEnabled: settings.autoPauseEnabled,
            nutritionAlertSoundEnabled: settings.nutritionAlertSoundEnabled,
            stravaAutoUploadEnabled: settings.stravaAutoUploadEnabled,
            stravaConnected: settings.stravaConnected,
            raceCountdownEnabled: settings.raceCountdownEnabled,
            biometricLockEnabled: settings.biometricLockEnabled,
            hydrationIntervalSeconds: settings.hydrationIntervalSeconds,
            fuelIntervalSeconds: settings.fuelIntervalSeconds,
            electrolyteIntervalSeconds: settings.electrolyteIntervalSeconds,
            smartRemindersEnabled: settings.smartRemindersEnabled,
            saveToHealthEnabled: settings.saveToHealthEnabled,
            healthKitAutoImportEnabled: settings.healthKitAutoImportEnabled,
            pacingAlertsEnabled: settings.pacingAlertsEnabled,
            recoveryRemindersEnabled: settings.recoveryRemindersEnabled,
            weeklySummaryEnabled: settings.weeklySummaryEnabled
        )
        model.voiceCoachingConfigData = try? JSONEncoder().encode(settings.voiceCoachingConfig)
        return model
    }
}
