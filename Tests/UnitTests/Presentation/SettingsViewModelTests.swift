import Foundation
import Testing
@testable import UltraTrain

@Suite("Settings ViewModel Tests")
struct SettingsViewModelTests {

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

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
            recoveryRemindersEnabled: true,
            weeklySummaryEnabled: true
        )
    }

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        settingsRepo: MockAppSettingsRepository = MockAppSettingsRepository(),
        clearUseCase: MockClearAllDataUseCase = MockClearAllDataUseCase(),
        healthKitService: MockHealthKitService = MockHealthKitService(),
        exportService: MockExportService = MockExportService(),
        runRepository: MockRunRepository = MockRunRepository(),
        stravaAuthService: MockStravaAuthService = MockStravaAuthService(),
        notificationService: MockNotificationService = MockNotificationService(),
        planRepository: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        raceRepository: MockRaceRepository = MockRaceRepository(),
        biometricAuthService: MockBiometricAuthService = MockBiometricAuthService(),
        healthKitImportService: MockHealthKitImportService? = nil
    ) -> SettingsViewModel {
        SettingsViewModel(
            athleteRepository: athleteRepo,
            appSettingsRepository: settingsRepo,
            clearAllDataUseCase: clearUseCase,
            healthKitService: healthKitService,
            exportService: exportService,
            runRepository: runRepository,
            stravaAuthService: stravaAuthService,
            notificationService: notificationService,
            planRepository: planRepository,
            raceRepository: raceRepository,
            biometricAuthService: biometricAuthService,
            healthKitImportService: healthKitImportService
        )
    }

    // MARK: - Load Tests

    @Test("Load fetches athlete and settings")
    @MainActor
    func loadFetchesAthleteAndSettings() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()

        #expect(vm.athlete != nil)
        #expect(vm.appSettings != nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load creates default settings when none exist")
    @MainActor
    func loadCreatesDefaultSettings() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()

        #expect(vm.appSettings != nil)
        #expect(vm.appSettings?.trainingRemindersEnabled == true)
        #expect(vm.appSettings?.nutritionRemindersEnabled == true)
        #expect(settingsRepo.savedSettings != nil)
    }

    @Test("Load handles error")
    @MainActor
    func loadHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Unit Preference Tests

    @Test("Update unit preference to imperial")
    @MainActor
    func updateUnitPreferenceToImperial() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateUnitPreference(.imperial)

        #expect(vm.athlete?.preferredUnit == .imperial)
        #expect(athleteRepo.savedAthlete?.preferredUnit == .imperial)
        #expect(vm.error == nil)
    }

    @Test("Update unit preference handles error")
    @MainActor
    func updateUnitPreferenceHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()

        athleteRepo.shouldThrow = true
        await vm.updateUnitPreference(.imperial)

        #expect(vm.error != nil)
    }

    // MARK: - Notification Toggle Tests

    @Test("Toggle training reminders off")
    @MainActor
    func toggleTrainingRemindersOff() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateTrainingReminders(false)

        #expect(vm.appSettings?.trainingRemindersEnabled == false)
        #expect(settingsRepo.savedSettings?.trainingRemindersEnabled == false)
    }

    @Test("Toggle nutrition reminders off")
    @MainActor
    func toggleNutritionRemindersOff() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateNutritionReminders(false)

        #expect(vm.appSettings?.nutritionRemindersEnabled == false)
        #expect(settingsRepo.savedSettings?.nutritionRemindersEnabled == false)
    }

    @Test("Update notification reminders handles error")
    @MainActor
    func updateNotificationRemindersHandlesError() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()

        settingsRepo.shouldThrow = true
        await vm.updateTrainingReminders(false)

        #expect(vm.error != nil)
    }

    // MARK: - Clear Data Tests

    @Test("Clear all data resets state")
    @MainActor
    func clearAllDataResetsState() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let clearUseCase = MockClearAllDataUseCase()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo, clearUseCase: clearUseCase)
        await vm.load()

        #expect(vm.athlete != nil)
        #expect(vm.appSettings != nil)

        await vm.clearAllData()

        #expect(vm.athlete == nil)
        #expect(vm.appSettings == nil)
        #expect(vm.didClearData == true)
        #expect(clearUseCase.executeCalled == true)
        #expect(vm.error == nil)
    }

    @Test("Clear all data handles error")
    @MainActor
    func clearAllDataHandlesError() async {
        let clearUseCase = MockClearAllDataUseCase()
        clearUseCase.shouldThrow = true

        let vm = makeViewModel(clearUseCase: clearUseCase)
        await vm.clearAllData()

        #expect(vm.error != nil)
        #expect(vm.didClearData == false)
    }

    // MARK: - HealthKit Tests

    @Test("Request HealthKit authorization succeeds and fetches data")
    @MainActor
    func requestHealthKitAuthorizationSucceeds() async {
        let hkService = MockHealthKitService()
        hkService.restingHR = 52
        hkService.maxHR = 190

        let vm = makeViewModel(healthKitService: hkService)
        await vm.requestHealthKitAuthorization()

        #expect(hkService.requestAuthorizationCalled == true)
        #expect(hkService.authorizationStatus == .authorized)
        #expect(vm.healthKitRestingHR == 52)
        #expect(vm.healthKitMaxHR == 190)
        #expect(vm.isRequestingHealthKit == false)
        #expect(vm.error == nil)
    }

    @Test("Request HealthKit authorization handles error")
    @MainActor
    func requestHealthKitAuthorizationHandlesError() async {
        let hkService = MockHealthKitService()
        hkService.shouldThrow = true

        let vm = makeViewModel(healthKitService: hkService)
        await vm.requestHealthKitAuthorization()

        #expect(hkService.requestAuthorizationCalled == true)
        #expect(vm.error != nil)
        #expect(vm.isRequestingHealthKit == false)
    }

    @Test("Fetch HealthKit data populates HR values")
    @MainActor
    func fetchHealthKitDataPopulatesHR() async {
        let hkService = MockHealthKitService()
        hkService.restingHR = 48
        hkService.maxHR = 195

        let vm = makeViewModel(healthKitService: hkService)
        await vm.fetchHealthKitData()

        #expect(vm.healthKitRestingHR == 48)
        #expect(vm.healthKitMaxHR == 195)
    }

    @Test("Update athlete with HealthKit data updates profile")
    @MainActor
    func updateAthleteWithHealthKitData() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let hkService = MockHealthKitService()
        hkService.restingHR = 45
        hkService.maxHR = 192

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService
        )
        await vm.load()
        await vm.fetchHealthKitData()
        await vm.updateAthleteWithHealthKitData()

        #expect(vm.athlete?.restingHeartRate == 45)
        #expect(vm.athlete?.maxHeartRate == 192)
        #expect(athleteRepo.savedAthlete?.restingHeartRate == 45)
        #expect(athleteRepo.savedAthlete?.maxHeartRate == 192)
        #expect(vm.error == nil)
    }

    @Test("Load auto-fetches HealthKit data when authorized")
    @MainActor
    func loadAutoFetchesHealthKitWhenAuthorized() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let hkService = MockHealthKitService()
        hkService.authorizationStatus = .authorized
        hkService.restingHR = 55
        hkService.maxHR = 180

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService
        )
        await vm.load()

        #expect(vm.healthKitRestingHR == 55)
        #expect(vm.healthKitMaxHR == 180)
    }

    // MARK: - Auto Pause Tests

    @Test("Toggle auto-pause off")
    @MainActor
    func toggleAutoPauseOff() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateAutoPause(false)

        #expect(vm.appSettings?.autoPauseEnabled == false)
        #expect(settingsRepo.savedSettings?.autoPauseEnabled == false)
    }

    // MARK: - Nutrition Interval Tests

    @Test("Update hydration interval")
    @MainActor
    func updateHydrationInterval() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateHydrationInterval(900)

        #expect(vm.appSettings?.hydrationIntervalSeconds == 900)
        #expect(settingsRepo.savedSettings?.hydrationIntervalSeconds == 900)
    }

    @Test("Update fuel interval")
    @MainActor
    func updateFuelInterval() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateFuelInterval(1800)

        #expect(vm.appSettings?.fuelIntervalSeconds == 1800)
        #expect(settingsRepo.savedSettings?.fuelIntervalSeconds == 1800)
    }

    @Test("Update electrolyte interval")
    @MainActor
    func updateElectrolyteInterval() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateElectrolyteInterval(1800)

        #expect(vm.appSettings?.electrolyteIntervalSeconds == 1800)
        #expect(settingsRepo.savedSettings?.electrolyteIntervalSeconds == 1800)
    }

    @Test("Update smart reminders toggle")
    @MainActor
    func updateSmartReminders() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        await vm.updateSmartReminders(true)

        #expect(vm.appSettings?.smartRemindersEnabled == true)
        #expect(settingsRepo.savedSettings?.smartRemindersEnabled == true)
    }

    // MARK: - HealthKit Body Weight Tests

    @Test("Fetch HealthKit data includes body weight")
    @MainActor
    func fetchHealthKitDataIncludesBodyWeight() async {
        let hkService = MockHealthKitService()
        hkService.restingHR = 50
        hkService.maxHR = 185
        hkService.bodyWeight = 72.5

        let vm = makeViewModel(healthKitService: hkService)
        await vm.fetchHealthKitData()

        #expect(vm.healthKitBodyWeight == 72.5)
        #expect(vm.healthKitRestingHR == 50)
    }

    @Test("Update athlete with HealthKit data includes body weight")
    @MainActor
    func updateAthleteWithHealthKitDataIncludesWeight() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let hkService = MockHealthKitService()
        hkService.bodyWeight = 68.0

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService
        )
        await vm.load()
        await vm.fetchHealthKitData()
        await vm.updateAthleteWithHealthKitData()

        #expect(vm.athlete?.weightKg == 68.0)
        #expect(athleteRepo.savedAthlete?.weightKg == 68.0)
    }

    @Test("Toggle save-to-health setting")
    @MainActor
    func toggleSaveToHealth() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()
        #expect(vm.appSettings?.saveToHealthEnabled == false)

        await vm.updateSaveToHealth(true)

        #expect(vm.appSettings?.saveToHealthEnabled == true)
        #expect(settingsRepo.savedSettings?.saveToHealthEnabled == true)
    }

    @Test("Update nutrition interval handles error")
    @MainActor
    func updateNutritionIntervalHandlesError() async {
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, settingsRepo: settingsRepo)
        await vm.load()

        settingsRepo.shouldThrow = true
        await vm.updateHydrationInterval(900)

        #expect(vm.error != nil)
    }

    // MARK: - HealthKit Auto-Import Tests

    @Test("Load triggers import when HealthKit authorized and auto-import enabled")
    @MainActor
    func loadTriggersImportWhenAuthorizedAndEnabled() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        var settings = makeSettings()
        settings.healthKitAutoImportEnabled = true
        settingsRepo.savedSettings = settings
        let hkService = MockHealthKitService()
        hkService.authorizationStatus = .authorized
        hkService.restingHR = 50
        hkService.maxHR = 185
        let importService = MockHealthKitImportService()
        importService.result = HealthKitImportResult(importedCount: 2, skippedCount: 1, matchedSessionCount: 1)

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService,
            healthKitImportService: importService
        )
        await vm.load()

        #expect(importService.importCalled == true)
        #expect(vm.lastImportResult?.importedCount == 2)
    }

    @Test("Enable auto-import triggers immediate import")
    @MainActor
    func enableAutoImportTriggersImport() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings()
        let hkService = MockHealthKitService()
        hkService.authorizationStatus = .authorized
        hkService.restingHR = 50
        hkService.maxHR = 185
        let importService = MockHealthKitImportService()
        importService.result = HealthKitImportResult(importedCount: 1, skippedCount: 0, matchedSessionCount: 0)

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService,
            healthKitImportService: importService
        )
        await vm.load()

        // Reset after load (load didn't trigger import since autoImport was false)
        importService.importCalled = false

        await vm.updateHealthKitAutoImport(true)

        #expect(vm.appSettings?.healthKitAutoImportEnabled == true)
        #expect(importService.importCalled == true)
        #expect(vm.lastImportResult?.importedCount == 1)
    }

    @Test("Disable auto-import saves setting without importing")
    @MainActor
    func disableAutoImportNoImport() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let settingsRepo = MockAppSettingsRepository()
        var settings = makeSettings()
        settings.healthKitAutoImportEnabled = true
        settingsRepo.savedSettings = settings
        let hkService = MockHealthKitService()
        hkService.authorizationStatus = .authorized
        hkService.restingHR = 50
        hkService.maxHR = 185
        let importService = MockHealthKitImportService()

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            settingsRepo: settingsRepo,
            healthKitService: hkService,
            healthKitImportService: importService
        )
        await vm.load()

        // Reset after load
        importService.importCalled = false

        await vm.updateHealthKitAutoImport(false)

        #expect(vm.appSettings?.healthKitAutoImportEnabled == false)
        #expect(importService.importCalled == false)
    }
}
