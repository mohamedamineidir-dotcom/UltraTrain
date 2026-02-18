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
            biometricLockEnabled: false
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
        biometricAuthService: MockBiometricAuthService = MockBiometricAuthService()
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
            biometricAuthService: biometricAuthService
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
}
