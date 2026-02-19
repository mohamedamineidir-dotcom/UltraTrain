import Foundation
import SwiftData
import os

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

        try context.save()
        Logger.persistence.info("App settings updated")
    }
}
