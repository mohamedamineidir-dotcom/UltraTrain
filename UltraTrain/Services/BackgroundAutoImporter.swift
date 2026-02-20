import Foundation
import os

struct AutoImportCheck: Sendable {
    let result: HealthKitImportResult?
    let importDate: Date?
}

final class BackgroundAutoImporter: Sendable {

    private static let throttleInterval: TimeInterval = 900 // 15 minutes

    private let healthKitService: any HealthKitServiceProtocol
    private let appSettingsRepository: any AppSettingsRepository
    private let athleteRepository: any AthleteRepository
    private let importService: any HealthKitImportServiceProtocol

    init(
        healthKitService: any HealthKitServiceProtocol,
        appSettingsRepository: any AppSettingsRepository,
        athleteRepository: any AthleteRepository,
        importService: any HealthKitImportServiceProtocol
    ) {
        self.healthKitService = healthKitService
        self.appSettingsRepository = appSettingsRepository
        self.athleteRepository = athleteRepository
        self.importService = importService
    }

    @MainActor
    func importIfNeeded(lastImportDate: Date?) async -> AutoImportCheck {
        do {
            guard healthKitService.authorizationStatus == .authorized else {
                return AutoImportCheck(result: nil, importDate: lastImportDate)
            }

            let settings = try await appSettingsRepository.getSettings()
            guard settings?.healthKitAutoImportEnabled == true else {
                return AutoImportCheck(result: nil, importDate: lastImportDate)
            }

            if let lastDate = lastImportDate,
               Date.now.timeIntervalSince(lastDate) < Self.throttleInterval {
                return AutoImportCheck(result: nil, importDate: lastImportDate)
            }

            guard let athlete = try await athleteRepository.getAthlete() else {
                return AutoImportCheck(result: nil, importDate: lastImportDate)
            }

            let result = try await importService.importNewWorkouts(athleteId: athlete.id)
            Logger.healthKit.info(
                "Background auto-import: \(result.importedCount) imported, \(result.skippedCount) skipped"
            )
            return AutoImportCheck(result: result, importDate: Date.now)
        } catch {
            Logger.healthKit.error("Background auto-import failed: \(error)")
            return AutoImportCheck(result: nil, importDate: lastImportDate)
        }
    }
}
