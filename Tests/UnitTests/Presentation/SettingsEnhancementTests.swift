import Testing
import Foundation
@testable import UltraTrain

@Suite("Settings Enhancement Tests")
struct SettingsEnhancementTests {

    @Test("AppearanceMode has correct raw values")
    func appearanceModeRawValues() {
        #expect(AppearanceMode.system.rawValue == "system")
        #expect(AppearanceMode.light.rawValue == "light")
        #expect(AppearanceMode.dark.rawValue == "dark")
    }

    @Test("AppearanceMode display names are correct")
    func appearanceModeDisplayNames() {
        #expect(AppearanceMode.system.displayName == "System")
        #expect(AppearanceMode.light.displayName == "Light")
        #expect(AppearanceMode.dark.displayName == "Dark")
    }

    @Test("AppearanceMode is CaseIterable")
    func appearanceModeCaseIterable() {
        #expect(AppearanceMode.allCases.count == 3)
    }

    @Test("AppSettings defaults for new fields")
    func appSettingsDefaults() {
        let settings = AppSettings(
            id: UUID(),
            trainingRemindersEnabled: true,
            nutritionRemindersEnabled: true,
            autoPauseEnabled: true,
            nutritionAlertSoundEnabled: true,
            stravaAutoUploadEnabled: false,
            stravaConnected: false,
            raceCountdownEnabled: true,
            biometricLockEnabled: false,
            hydrationIntervalSeconds: 1200,
            fuelIntervalSeconds: 2700,
            electrolyteIntervalSeconds: 0,
            smartRemindersEnabled: false,
            saveToHealthEnabled: false,
            healthKitAutoImportEnabled: false,
            pacingAlertsEnabled: true,
            recoveryRemindersEnabled: true,
            weeklySummaryEnabled: true
        )
        #expect(settings.appearanceMode == .system)
        #expect(settings.quietHoursEnabled == false)
        #expect(settings.quietHoursStart == 22)
        #expect(settings.quietHoursEnd == 7)
        #expect(settings.dataRetentionMonths == 0)
    }

    @Test("AppSettingsSwiftDataModel defaults for new fields")
    func swiftDataModelDefaults() {
        let model = AppSettingsSwiftDataModel()
        #expect(model.appearanceModeRaw == "system")
        #expect(model.quietHoursEnabled == false)
        #expect(model.quietHoursStart == 22)
        #expect(model.quietHoursEnd == 7)
        #expect(model.dataRetentionMonths == 0)
    }

    @Test("AppSettingsSwiftDataMapper maps new fields to domain")
    func mapperToDomain() {
        let model = AppSettingsSwiftDataModel()
        model.appearanceModeRaw = "dark"
        model.quietHoursEnabled = true
        model.quietHoursStart = 23
        model.quietHoursEnd = 6
        model.dataRetentionMonths = 12

        let domain = AppSettingsSwiftDataMapper.toDomain(model)
        #expect(domain.appearanceMode == .dark)
        #expect(domain.quietHoursEnabled == true)
        #expect(domain.quietHoursStart == 23)
        #expect(domain.quietHoursEnd == 6)
        #expect(domain.dataRetentionMonths == 12)
    }

    @Test("AppSettingsSwiftDataMapper maps new fields to SwiftData")
    func mapperToSwiftData() {
        let domain = AppSettings(
            id: UUID(),
            trainingRemindersEnabled: true,
            nutritionRemindersEnabled: true,
            autoPauseEnabled: true,
            nutritionAlertSoundEnabled: true,
            stravaAutoUploadEnabled: false,
            stravaConnected: false,
            raceCountdownEnabled: true,
            biometricLockEnabled: false,
            hydrationIntervalSeconds: 1200,
            fuelIntervalSeconds: 2700,
            electrolyteIntervalSeconds: 0,
            smartRemindersEnabled: false,
            saveToHealthEnabled: false,
            healthKitAutoImportEnabled: false,
            pacingAlertsEnabled: true,
            recoveryRemindersEnabled: true,
            weeklySummaryEnabled: true,
            appearanceMode: .light,
            quietHoursEnabled: true,
            quietHoursStart: 21,
            quietHoursEnd: 8,
            dataRetentionMonths: 6
        )

        let model = AppSettingsSwiftDataMapper.toSwiftData(domain)
        #expect(model.appearanceModeRaw == "light")
        #expect(model.quietHoursEnabled == true)
        #expect(model.quietHoursStart == 21)
        #expect(model.quietHoursEnd == 8)
        #expect(model.dataRetentionMonths == 6)
    }
}
