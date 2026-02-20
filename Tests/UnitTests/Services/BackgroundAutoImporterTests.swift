import Foundation
import Testing
@testable import UltraTrain

@Suite("BackgroundAutoImporter Tests")
struct BackgroundAutoImporterTests {

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
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

    private func makeSettings(autoImportEnabled: Bool = true) -> AppSettings {
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
            healthKitAutoImportEnabled: autoImportEnabled,
            pacingAlertsEnabled: true
        )
    }

    private func makeImporter(
        hkService: MockHealthKitService = MockHealthKitService(),
        settingsRepo: MockAppSettingsRepository = MockAppSettingsRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        importService: MockHealthKitImportService = MockHealthKitImportService()
    ) -> (BackgroundAutoImporter, MockHealthKitImportService) {
        let importer = BackgroundAutoImporter(
            healthKitService: hkService,
            appSettingsRepository: settingsRepo,
            athleteRepository: athleteRepo,
            importService: importService
        )
        return (importer, importService)
    }

    // MARK: - Skip Cases

    @Test("Skips when HealthKit not authorized")
    @MainActor
    func skipsWhenNotAuthorized() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .notDetermined
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let importService = MockHealthKitImportService()

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let check = await importer.importIfNeeded(lastImportDate: nil)

        #expect(check.result == nil)
        #expect(importService.importCalled == false)
    }

    @Test("Skips when auto-import disabled")
    @MainActor
    func skipsWhenDisabled() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: false)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let importService = MockHealthKitImportService()

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let check = await importer.importIfNeeded(lastImportDate: nil)

        #expect(check.result == nil)
        #expect(importService.importCalled == false)
    }

    @Test("Skips when no athlete profile")
    @MainActor
    func skipsWhenNoAthlete() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: true)
        let athleteRepo = MockAthleteRepository()
        let importService = MockHealthKitImportService()

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let check = await importer.importIfNeeded(lastImportDate: nil)

        #expect(check.result == nil)
        #expect(importService.importCalled == false)
    }

    @Test("Skips when throttled — last import less than 15 min ago")
    @MainActor
    func skipsWhenThrottled() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let importService = MockHealthKitImportService()

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let recentDate = Date.now.addingTimeInterval(-300) // 5 min ago
        let check = await importer.importIfNeeded(lastImportDate: recentDate)

        #expect(check.result == nil)
        #expect(check.importDate == recentDate)
        #expect(importService.importCalled == false)
    }

    // MARK: - Import Cases

    @Test("Imports on first launch when lastImportDate is nil")
    @MainActor
    func importsOnFirstLaunch() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let importService = MockHealthKitImportService()
        importService.result = HealthKitImportResult(
            importedCount: 3, skippedCount: 1, matchedSessionCount: 2
        )

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let check = await importer.importIfNeeded(lastImportDate: nil)

        #expect(importService.importCalled == true)
        #expect(importService.importAthleteId == athleteId)
        #expect(check.result?.importedCount == 3)
        #expect(check.result?.skippedCount == 1)
        #expect(check.result?.matchedSessionCount == 2)
        #expect(check.importDate != nil)
    }

    @Test("Imports when past throttle window")
    @MainActor
    func importsWhenPastThrottleWindow() async {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        let settingsRepo = MockAppSettingsRepository()
        settingsRepo.savedSettings = makeSettings(autoImportEnabled: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let importService = MockHealthKitImportService()
        importService.result = HealthKitImportResult(
            importedCount: 1, skippedCount: 0, matchedSessionCount: 0
        )

        let (importer, _) = makeImporter(
            hkService: hk,
            settingsRepo: settingsRepo,
            athleteRepo: athleteRepo,
            importService: importService
        )
        let oldDate = Date.now.addingTimeInterval(-1800) // 30 min ago
        let check = await importer.importIfNeeded(lastImportDate: oldDate)

        #expect(importService.importCalled == true)
        #expect(check.result?.importedCount == 1)
        #expect(check.importDate != nil)
        #expect(check.importDate != oldDate)
    }
}
