import Foundation
import Testing
@testable import UltraTrain

@MainActor
@Suite("SafetySettingsViewModel Tests")
struct SafetySettingsViewModelTests {

    // MARK: - Helpers

    private func makeSettings(
        safetyConfig: SafetyConfig = SafetyConfig()
    ) -> AppSettings {
        AppSettings(
            id: UUID(),
            trainingRemindersEnabled: false,
            nutritionRemindersEnabled: false,
            autoPauseEnabled: false,
            nutritionAlertSoundEnabled: false,
            stravaAutoUploadEnabled: false,
            stravaConnected: false,
            raceCountdownEnabled: false,
            biometricLockEnabled: false,
            hydrationIntervalSeconds: 900,
            fuelIntervalSeconds: 1800,
            electrolyteIntervalSeconds: 1800,
            smartRemindersEnabled: false,
            saveToHealthEnabled: false,
            healthKitAutoImportEnabled: false,
            pacingAlertsEnabled: false,
            recoveryRemindersEnabled: false,
            weeklySummaryEnabled: false,
            safetyConfig: safetyConfig
        )
    }

    private func makeViewModel(
        repo: MockAppSettingsRepository = MockAppSettingsRepository()
    ) -> SafetySettingsViewModel {
        SafetySettingsViewModel(appSettingsRepository: repo)
    }

    // MARK: - Load

    @Test("Load fetches settings from repository")
    func load_fetchesSettings() async {
        let repo = MockAppSettingsRepository()
        let customConfig = SafetyConfig(
            sosEnabled: true,
            fallDetectionEnabled: false,
            noMovementAlertEnabled: true,
            noMovementThresholdMinutes: 10,
            safetyTimerEnabled: true,
            safetyTimerDurationMinutes: 60,
            countdownBeforeSendingSeconds: 15,
            includeLocationInMessage: false
        )
        repo.savedSettings = makeSettings(safetyConfig: customConfig)

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.config.sosEnabled == true)
        #expect(vm.config.fallDetectionEnabled == false)
        #expect(vm.config.noMovementAlertEnabled == true)
        #expect(vm.config.noMovementThresholdMinutes == 10)
        #expect(vm.config.safetyTimerEnabled == true)
        #expect(vm.config.safetyTimerDurationMinutes == 60)
        #expect(vm.config.countdownBeforeSendingSeconds == 15)
        #expect(vm.config.includeLocationInMessage == false)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles missing settings gracefully")
    func load_handlesMissingSettings() async {
        let repo = MockAppSettingsRepository()
        repo.savedSettings = nil

        let vm = makeViewModel(repo: repo)
        await vm.load()

        // Should keep default config values
        #expect(vm.config == SafetyConfig())
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles error")
    func load_handlesError() async {
        let repo = MockAppSettingsRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Save

    @Test("Save persists config changes to repository")
    func save_persistsConfigChanges() async {
        let repo = MockAppSettingsRepository()
        repo.savedSettings = makeSettings()

        let vm = makeViewModel(repo: repo)
        await vm.load()

        vm.config.sosEnabled = false
        vm.config.fallDetectionEnabled = true
        vm.config.noMovementThresholdMinutes = 15

        await vm.save()

        #expect(repo.savedSettings?.safetyConfig.sosEnabled == false)
        #expect(repo.savedSettings?.safetyConfig.fallDetectionEnabled == true)
        #expect(repo.savedSettings?.safetyConfig.noMovementThresholdMinutes == 15)
        #expect(vm.error == nil)
    }

    @Test("Save handles error")
    func save_handlesError() async {
        let repo = MockAppSettingsRepository()
        repo.savedSettings = makeSettings()

        let vm = makeViewModel(repo: repo)
        await vm.load()

        repo.shouldThrow = true
        await vm.save()

        #expect(vm.error != nil)
    }

    // MARK: - Default Config

    @Test("Default config values match SafetyConfig defaults")
    func defaultConfigValues() {
        let vm = makeViewModel()

        #expect(vm.config.sosEnabled == true)
        #expect(vm.config.fallDetectionEnabled == true)
        #expect(vm.config.noMovementAlertEnabled == true)
        #expect(vm.config.noMovementThresholdMinutes == 5)
        #expect(vm.config.safetyTimerEnabled == false)
        #expect(vm.config.safetyTimerDurationMinutes == 120)
        #expect(vm.config.countdownBeforeSendingSeconds == 30)
        #expect(vm.config.includeLocationInMessage == true)
    }
}
