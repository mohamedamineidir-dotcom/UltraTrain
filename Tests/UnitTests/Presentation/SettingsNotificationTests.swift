import Foundation
import Testing
@testable import UltraTrain

@Suite("Settings Notification Tests")
@MainActor
struct SettingsNotificationTests {

    private func makeSettings() -> AppSettings {
        AppSettings(
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
            recoveryRemindersEnabled: false,
            weeklySummaryEnabled: false
        )
    }

    private func makeViewModel(
        settingsRepo: MockAppSettingsRepository = MockAppSettingsRepository(),
        notificationService: MockNotificationService = MockNotificationService()
    ) -> (SettingsViewModel, MockAppSettingsRepository, MockNotificationService) {
        let vm = SettingsViewModel(
            athleteRepository: MockAthleteRepository(),
            appSettingsRepository: settingsRepo,
            clearAllDataUseCase: MockClearAllDataUseCase(),
            healthKitService: MockHealthKitService(),
            exportService: MockExportService(),
            runRepository: MockRunRepository(),
            stravaAuthService: MockStravaAuthService(),
            notificationService: notificationService,
            planRepository: MockTrainingPlanRepository(),
            raceRepository: MockRaceRepository(),
            biometricAuthService: MockBiometricAuthService()
        )
        return (vm, settingsRepo, notificationService)
    }

    @Test("Recovery reminders enable requests authorization and reschedules")
    func enableRecoveryReminders() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let notifService = MockNotificationService()
        let (vm, _, _) = makeViewModel(settingsRepo: settingsRepo, notificationService: notifService)

        vm.appSettings = settingsRepo.savedSettings
        await vm.updateRecoveryReminders(true)

        #expect(vm.appSettings?.recoveryRemindersEnabled == true)
        #expect(notifService.requestAuthorizationCalled == true)
        #expect(vm.error == nil)
    }

    @Test("Recovery reminders disable cancels recovery notifications")
    func disableRecoveryReminders() async {
        let settingsRepo = MockAppSettingsRepository()
        var settings = makeSettings()
        settings.recoveryRemindersEnabled = true
        settingsRepo.savedSettings = settings
        let notifService = MockNotificationService()
        let (vm, _, _) = makeViewModel(settingsRepo: settingsRepo, notificationService: notifService)

        vm.appSettings = settingsRepo.savedSettings
        await vm.updateRecoveryReminders(false)

        #expect(vm.appSettings?.recoveryRemindersEnabled == false)
        #expect(notifService.cancelledPrefixes.contains("recovery-"))
        #expect(notifService.requestAuthorizationCalled == false)
    }

    @Test("Weekly summary enable requests authorization")
    func enableWeeklySummary() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let notifService = MockNotificationService()
        let (vm, _, _) = makeViewModel(settingsRepo: settingsRepo, notificationService: notifService)

        vm.appSettings = settingsRepo.savedSettings
        await vm.updateWeeklySummary(true)

        #expect(vm.appSettings?.weeklySummaryEnabled == true)
        #expect(notifService.requestAuthorizationCalled == true)
        #expect(vm.error == nil)
    }

    @Test("Weekly summary disable cancels weekly notifications")
    func disableWeeklySummary() async {
        let settingsRepo = MockAppSettingsRepository()
        var settings = makeSettings()
        settings.weeklySummaryEnabled = true
        settingsRepo.savedSettings = settings
        let notifService = MockNotificationService()
        let (vm, _, _) = makeViewModel(settingsRepo: settingsRepo, notificationService: notifService)

        vm.appSettings = settingsRepo.savedSettings
        await vm.updateWeeklySummary(false)

        #expect(vm.appSettings?.weeklySummaryEnabled == false)
        #expect(notifService.cancelledPrefixes.contains("weekly-"))
        #expect(notifService.requestAuthorizationCalled == false)
    }
}
