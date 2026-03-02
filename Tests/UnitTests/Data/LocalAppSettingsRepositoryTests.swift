import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalAppSettingsRepository Tests")
@MainActor
struct LocalAppSettingsRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([AppSettingsSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSettings(
        id: UUID = UUID(),
        trainingRemindersEnabled: Bool = true,
        autoPauseEnabled: Bool = true,
        biometricLockEnabled: Bool = false
    ) -> AppSettings {
        AppSettings(
            id: id,
            trainingRemindersEnabled: trainingRemindersEnabled,
            nutritionRemindersEnabled: true,
            autoPauseEnabled: autoPauseEnabled,
            nutritionAlertSoundEnabled: true,
            stravaAutoUploadEnabled: false,
            stravaConnected: false,
            raceCountdownEnabled: true,
            biometricLockEnabled: biometricLockEnabled,
            hydrationIntervalSeconds: 1200,
            fuelIntervalSeconds: 1800,
            electrolyteIntervalSeconds: 2400,
            smartRemindersEnabled: true,
            saveToHealthEnabled: true,
            healthKitAutoImportEnabled: false,
            pacingAlertsEnabled: true,
            recoveryRemindersEnabled: true,
            weeklySummaryEnabled: true
        )
    }

    @Test("Save and get settings")
    func saveAndGetSettings() async throws {
        let container = try makeContainer()
        let repo = LocalAppSettingsRepository(modelContainer: container)

        let settings = makeSettings(trainingRemindersEnabled: true)
        try await repo.saveSettings(settings)

        let fetched = try await repo.getSettings()
        #expect(fetched != nil)
        #expect(fetched?.trainingRemindersEnabled == true)
    }

    @Test("Get settings returns nil when none saved")
    func getSettingsReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalAppSettingsRepository(modelContainer: container)

        let fetched = try await repo.getSettings()
        #expect(fetched == nil)
    }

    @Test("Update settings modifies existing record")
    func updateSettingsModifiesExisting() async throws {
        let container = try makeContainer()
        let repo = LocalAppSettingsRepository(modelContainer: container)
        let settingsId = UUID()

        let original = makeSettings(id: settingsId, autoPauseEnabled: true)
        try await repo.saveSettings(original)

        var updated = original
        updated.autoPauseEnabled = false
        updated.biometricLockEnabled = true
        try await repo.updateSettings(updated)

        let fetched = try await repo.getSettings()
        #expect(fetched?.autoPauseEnabled == false)
        #expect(fetched?.biometricLockEnabled == true)
    }

    @Test("Update settings throws when settings not found")
    func updateSettingsThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalAppSettingsRepository(modelContainer: container)

        let settings = makeSettings()
        await #expect(throws: DomainError.self) {
            try await repo.updateSettings(settings)
        }
    }

    @Test("Save preserves all notification interval fields")
    func savePreservesIntervalFields() async throws {
        let container = try makeContainer()
        let repo = LocalAppSettingsRepository(modelContainer: container)

        var settings = makeSettings()
        settings.hydrationIntervalSeconds = 900
        settings.fuelIntervalSeconds = 2700
        settings.electrolyteIntervalSeconds = 3600
        try await repo.saveSettings(settings)

        let fetched = try await repo.getSettings()
        #expect(fetched?.hydrationIntervalSeconds == 900)
        #expect(fetched?.fuelIntervalSeconds == 2700)
        #expect(fetched?.electrolyteIntervalSeconds == 3600)
    }
}
