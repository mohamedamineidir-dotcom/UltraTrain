import Foundation

enum AppSettingsSwiftDataMapper {
    static func toDomain(_ model: AppSettingsSwiftDataModel) -> AppSettings {
        AppSettings(
            id: model.id,
            trainingRemindersEnabled: model.trainingRemindersEnabled,
            nutritionRemindersEnabled: model.nutritionRemindersEnabled,
            autoPauseEnabled: model.autoPauseEnabled,
            nutritionAlertSoundEnabled: model.nutritionAlertSoundEnabled
        )
    }

    static func toSwiftData(_ settings: AppSettings) -> AppSettingsSwiftDataModel {
        AppSettingsSwiftDataModel(
            id: settings.id,
            trainingRemindersEnabled: settings.trainingRemindersEnabled,
            nutritionRemindersEnabled: settings.nutritionRemindersEnabled,
            autoPauseEnabled: settings.autoPauseEnabled,
            nutritionAlertSoundEnabled: settings.nutritionAlertSoundEnabled
        )
    }
}
