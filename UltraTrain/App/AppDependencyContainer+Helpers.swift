import SwiftData
import os

extension AppDependencyContainer {

    // MARK: - ModelContainer

    static func createModelContainer(isUITesting: Bool, iCloudEnabled: Bool) -> ModelContainer {
        do {
            let schema = Schema(SchemaV1.models)
            let config: ModelConfiguration
            if isUITesting {
                config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            } else if iCloudEnabled {
                config = ModelConfiguration(
                    cloudKitDatabase: .private("iCloud.com.ultratrain.app")
                )
            } else {
                config = ModelConfiguration(cloudKitDatabase: .none)
            }
            return try ModelContainer(
                for: schema,
                migrationPlan: UltraTrainMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - CloudKit

    struct CloudKitConfiguration {
        let monitor: CloudKitSyncMonitor?
        let sharingService: (any CloudKitSharingServiceProtocol)?
        let crewService: any CrewTrackingServiceProtocol
    }

    static func configureCloudKit(
        iCloudEnabled: Bool,
        modelContainer: ModelContainer
    ) -> CloudKitConfiguration {
        if iCloudEnabled {
            let monitor = CloudKitSyncMonitor()
            monitor.startMonitoring(modelContainer: modelContainer)
            let container = modelContainer
            Task {
                try? await Task.sleep(for: .seconds(3))
                await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)
            }
            let accountManager = CloudKitAccountManager()
            return CloudKitConfiguration(
                monitor: monitor,
                sharingService: CloudKitSharingService(accountManager: accountManager),
                crewService: CloudKitCrewTrackingService(accountManager: accountManager)
            )
        } else {
            return CloudKitConfiguration(
                monitor: nil,
                sharingService: nil,
                crewService: CrewTrackingService()
            )
        }
    }

    // MARK: - Background Tasks

    static func startBackgroundTasks(
        stravaUploadQueueService: StravaUploadQueueService,
        syncService: SyncService,
        notificationService: NotificationService,
        connectivityService: PhoneConnectivityService,
        watchRunImportService: WatchRunImportService,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository
    ) {
        let queueService = stravaUploadQueueService
        Task { await queueService.processQueue() }

        let syncSvc = syncService
        Task { await syncSvc.processQueue() }

        let notifService = notificationService
        Task { await notifService.registerNotificationCategories() }

        connectivityService.completedRunHandler = {
            [watchRunImportService, athleteRepository, runRepository, connectivityService] runData in
            Task {
                do {
                    guard let athlete = try await athleteRepository.getAthlete() else {
                        Logger.watch.warning("Cannot import watch run — no athlete profile")
                        return
                    }
                    try await watchRunImportService.importWatchRun(runData, athleteId: athlete.id)

                    let recentRuns = try await runRepository.getRecentRuns(limit: 10)
                    let historyData = recentRuns.map { run in
                        WatchRunHistoryData(
                            id: run.id,
                            date: run.date,
                            distanceKm: run.distanceKm,
                            elevationGainM: run.elevationGainM,
                            duration: run.duration,
                            averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
                            averageHeartRate: run.averageHeartRate
                        )
                    }
                    connectivityService.sendRunHistory(historyData)
                } catch {
                    Logger.watch.error("Failed to import watch run: \(error)")
                }
            }
        }
    }
}
