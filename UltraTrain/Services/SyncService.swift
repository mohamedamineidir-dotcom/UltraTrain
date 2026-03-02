import Foundation
import os

// @unchecked Sendable: immutable after init
final class SyncService: SyncQueueServiceProtocol, @unchecked Sendable {
    private let queueRepository: any SyncQueueRepository
    private let localRunRepository: any RunRepository
    private let remoteRunDataSource: RemoteRunDataSource
    private let authService: any AuthServiceProtocol
    private let remoteAthleteDataSource: RemoteAthleteDataSource?
    private let localAthleteRepository: (any AthleteRepository)?
    private let remoteRaceDataSource: RemoteRaceDataSource?
    private let localRaceRepository: (any RaceRepository)?
    private let remoteTrainingPlanDataSource: RemoteTrainingPlanDataSource?
    private let localTrainingPlanRepository: (any TrainingPlanRepository)?
    private let trainingPlanSyncService: TrainingPlanSyncService?
    private let socialSyncHandler: SocialSyncHandler?
    private let backgroundUploadService: (any BackgroundUploadServiceProtocol)?

    init(
        queueRepository: any SyncQueueRepository,
        localRunRepository: any RunRepository,
        remoteRunDataSource: RemoteRunDataSource,
        authService: any AuthServiceProtocol,
        remoteAthleteDataSource: RemoteAthleteDataSource? = nil,
        localAthleteRepository: (any AthleteRepository)? = nil,
        remoteRaceDataSource: RemoteRaceDataSource? = nil,
        localRaceRepository: (any RaceRepository)? = nil,
        remoteTrainingPlanDataSource: RemoteTrainingPlanDataSource? = nil,
        localTrainingPlanRepository: (any TrainingPlanRepository)? = nil,
        trainingPlanSyncService: TrainingPlanSyncService? = nil,
        socialSyncHandler: SocialSyncHandler? = nil,
        backgroundUploadService: (any BackgroundUploadServiceProtocol)? = nil
    ) {
        self.queueRepository = queueRepository
        self.localRunRepository = localRunRepository
        self.remoteRunDataSource = remoteRunDataSource
        self.authService = authService
        self.remoteAthleteDataSource = remoteAthleteDataSource
        self.localAthleteRepository = localAthleteRepository
        self.remoteRaceDataSource = remoteRaceDataSource
        self.localRaceRepository = localRaceRepository
        self.remoteTrainingPlanDataSource = remoteTrainingPlanDataSource
        self.localTrainingPlanRepository = localTrainingPlanRepository
        self.trainingPlanSyncService = trainingPlanSyncService
        self.socialSyncHandler = socialSyncHandler
        self.backgroundUploadService = backgroundUploadService
    }

    func enqueueUpload(runId: UUID) async throws {
        try await enqueueOperation(.runUpload, entityId: runId)
    }

    func enqueueOperation(_ type: SyncOperationType, entityId: UUID) async throws {
        let items = try await queueRepository.getPendingItems()
        if let existing = items.first(where: { $0.operationType == type && $0.entityId == entityId }) {
            if existing.status == .completed { return }
            var reset = existing
            reset.status = .pending
            reset.retryCount = 0
            reset.errorMessage = nil
            try await queueRepository.updateItem(reset)
        } else {
            let item = SyncQueueItem(
                id: UUID(),
                runId: type == .runUpload ? entityId : UUID(),
                operationType: type,
                entityId: entityId,
                status: .pending,
                retryCount: 0,
                lastAttempt: nil,
                errorMessage: nil,
                createdAt: Date()
            )
            try await queueRepository.saveItem(item)
        }
        Logger.network.info("SyncService: queued \(type.rawValue) for entity \(entityId)")
        await processQueue()
    }

    func processQueue() async {
        guard authService.isAuthenticated() else { return }

        do {
            let items = try await queueRepository.getPendingItems()
            for item in items {
                if let lastAttempt = item.lastAttempt {
                    let elapsed = Date().timeIntervalSince(lastAttempt)
                    if elapsed < item.nextRetryDelay { continue }
                }
                await processItem(item)
            }
        } catch {
            Logger.network.error("SyncService: failed to fetch queue: \(error)")
        }
    }

    func getQueueStatus(forRunId runId: UUID) async -> SyncQueueItemStatus? {
        do {
            return try await queueRepository.getItem(forRunId: runId)?.status
        } catch {
            Logger.network.warning("SyncService: failed to get queue status for run \(runId): \(error)")
            return nil
        }
    }

    func getPendingCount() async -> Int {
        do {
            return try await queueRepository.getPendingCount()
        } catch {
            Logger.network.warning("SyncService: failed to get pending count: \(error)")
            return 0
        }
    }

    func getFailedCount() async -> Int {
        do {
            return try await queueRepository.getFailedCount()
        } catch {
            Logger.network.warning("SyncService: failed to get failed count: \(error)")
            return 0
        }
    }

    func getFailedItems() async -> [SyncQueueItem] {
        do {
            return try await queueRepository.getFailedItems()
        } catch {
            Logger.network.warning("SyncService: failed to get failed items: \(error)")
            return []
        }
    }

    func retryItem(id: UUID) async {
        do {
            let items = try await queueRepository.getPendingItems()
            let failed = try await queueRepository.getFailedItems()
            let allItems = items + failed
            guard var item = allItems.first(where: { $0.id == id }) else { return }
            item.status = .pending
            item.retryCount = 0
            item.errorMessage = nil
            try await queueRepository.updateItem(item)
            await processQueue()
        } catch {
            Logger.network.error("SyncService: retryItem failed: \(error)")
        }
    }

    func discardItem(id: UUID) async {
        do {
            try await queueRepository.deleteItem(id: id)
            Logger.network.info("SyncService: discarded item \(id)")
        } catch {
            Logger.network.error("SyncService: discardItem failed: \(error)")
        }
    }

    func retryAllFailed() async {
        let failed = await getFailedItems()
        for item in failed {
            await retryItem(id: item.id)
        }
    }

    func discardAllFailed() async {
        let failed = await getFailedItems()
        for item in failed {
            await discardItem(id: item.id)
        }
    }

    // MARK: - Private

    private func processItem(_ item: SyncQueueItem) async {
        var mutable = item
        mutable.status = .uploading
        mutable.lastAttempt = Date()
        do {
            try await queueRepository.updateItem(mutable)
        } catch {
            Logger.network.warning("SyncService: failed to mark item as uploading for \(item.operationType.rawValue) \(item.entityId): \(error)")
        }

        do {
            switch item.operationType {
            case .runUpload:
                try await processRunUpload(item)
            case .athleteSync:
                try await processAthleteSync(item)
            case .raceSync:
                try await processRaceSync(item)
            case .raceDelete:
                try await processRaceDelete(item)
            case .trainingPlanSync:
                try await processTrainingPlanSync(item)
            case .nutritionPlanSync:
                try await processNutritionPlanSync(item)
            case .fitnessSnapshotSync:
                try await processFitnessSnapshotSync(item)
            case .finishEstimateSync:
                try await processFinishEstimateSync(item)
            case .socialProfileSync, .activityPublish, .shareRevoke:
                try await socialSyncHandler?.process(item)
            }

            mutable.status = .completed
            do {
                try await queueRepository.updateItem(mutable)
            } catch {
                Logger.network.warning("SyncService: failed to mark item as completed for \(item.operationType.rawValue) \(item.entityId): \(error)")
            }
            Logger.network.info("SyncService: completed \(item.operationType.rawValue) for \(item.entityId)")
        } catch let error as APIError {
            switch error {
            case .conflict:
                mutable.status = .failed
                mutable.retryCount = 5
                mutable.errorMessage = "Conflict: data was modified on another device"
                Logger.network.warning("SyncService: conflict for \(item.operationType.rawValue) \(item.entityId) — server has newer version")
            case .clientError, .unauthorized, .invalidURL, .decodingError:
                mutable.status = .failed
                mutable.retryCount = 5
                mutable.errorMessage = error.localizedDescription
                Logger.network.error("SyncService: permanent failure for \(item.operationType.rawValue) \(item.entityId): \(error)")
            default:
                mutable.retryCount += 1
                mutable.errorMessage = error.localizedDescription
                mutable.status = mutable.hasReachedMaxRetries ? .failed : .pending
                Logger.network.warning("SyncService: retryable failure for \(item.operationType.rawValue) \(item.entityId) (attempt \(mutable.retryCount)): \(error)")
            }
            do {
                try await queueRepository.updateItem(mutable)
            } catch let updateError {
                Logger.network.warning("SyncService: failed to update queue item after API error for \(item.operationType.rawValue) \(item.entityId): \(updateError)")
            }
        } catch {
            mutable.retryCount += 1
            mutable.errorMessage = error.localizedDescription
            mutable.status = mutable.hasReachedMaxRetries ? .failed : .pending
            do {
                try await queueRepository.updateItem(mutable)
            } catch let updateError {
                Logger.network.warning("SyncService: failed to update queue item after error for \(item.operationType.rawValue) \(item.entityId): \(updateError)")
            }
            Logger.network.warning("SyncService: error for \(item.operationType.rawValue) \(item.entityId): \(error)")
        }
    }

    private func processRunUpload(_ item: SyncQueueItem) async throws {
        guard var run = try await localRunRepository.getRun(id: item.entityId) else {
            do {
                try await queueRepository.deleteItem(id: item.id)
            } catch {
                Logger.network.warning("SyncService: failed to remove orphaned run queue item \(item.id): \(error)")
            }
            Logger.network.info("SyncService: run \(item.entityId) not found, removed from queue")
            return
        }
        let dto = RunMapper.toUploadDTO(run)

        // Use background URLSession for runs with large GPS tracks
        if run.gpsTrack.count >= BackgroundUploadService.gpsThreshold,
           let bgService = backgroundUploadService {
            try await bgService.uploadRun(dto: dto, syncItemId: item.id)
            Logger.network.info("SyncService: delegated large run \(item.entityId) to background upload (\(run.gpsTrack.count) points)")
            return
        }

        let response = try await remoteRunDataSource.uploadRun(dto)
        // Update serverUpdatedAt from the response so future syncs can detect conflicts
        if let updatedAtStr = response.updatedAt,
           let updatedAt = ISO8601DateFormatter().date(from: updatedAtStr) {
            run.serverUpdatedAt = updatedAt
            do {
                try await localRunRepository.updateRun(run)
            } catch {
                Logger.network.warning("SyncService: failed to save serverUpdatedAt for run \(item.entityId): \(error)")
            }
        }
    }

    private func processAthleteSync(_ item: SyncQueueItem) async throws {
        guard let repo = localAthleteRepository,
              let remote = remoteAthleteDataSource else { return }
        guard let athlete = try await repo.getAthlete() else {
            do {
                try await queueRepository.deleteItem(id: item.id)
            } catch {
                Logger.network.warning("SyncService: failed to remove orphaned athlete queue item \(item.id): \(error)")
            }
            return
        }
        let dto = AthleteMapper.toDTO(athlete)
        _ = try await remote.updateAthlete(dto)
    }

    private func processRaceSync(_ item: SyncQueueItem) async throws {
        guard let repo = localRaceRepository,
              let remote = remoteRaceDataSource else { return }
        guard var race = try await repo.getRace(id: item.entityId) else {
            do {
                try await queueRepository.deleteItem(id: item.id)
            } catch {
                Logger.network.warning("SyncService: failed to remove orphaned race queue item \(item.id): \(error)")
            }
            return
        }
        guard let dto = RaceRemoteMapper.toUploadDTO(race) else { return }
        let response = try await remote.upsertRace(dto)
        // Update serverUpdatedAt from the response so future syncs can detect conflicts
        if let updatedAtStr = response.updatedAt,
           let updatedAt = ISO8601DateFormatter().date(from: updatedAtStr) {
            race.serverUpdatedAt = updatedAt
            do {
                try await repo.saveRace(race)
            } catch {
                Logger.network.warning("SyncService: failed to save serverUpdatedAt for race \(item.entityId): \(error)")
            }
        }
    }

    private func processRaceDelete(_ item: SyncQueueItem) async throws {
        guard let remote = remoteRaceDataSource else { return }
        try await remote.deleteRace(id: item.entityId.uuidString)
    }

    private func processTrainingPlanSync(_ item: SyncQueueItem) async throws {
        guard let repo = localTrainingPlanRepository,
              let syncService = trainingPlanSyncService else { return }
        guard let plan = try await repo.getActivePlan() else {
            do {
                try await queueRepository.deleteItem(id: item.id)
            } catch {
                Logger.network.warning("SyncService: failed to remove orphaned training plan queue item \(item.id): \(error)")
            }
            return
        }
        await syncService.syncPlan(plan)
    }

    // Nutrition, fitness, and finish estimate sync use direct fire-and-forget from their
    // SyncedRepositories. These queue handlers exist only as safety nets to clean up
    // any stale items that might end up in the queue.
    private func processNutritionPlanSync(_ item: SyncQueueItem) async throws {
        do {
            try await queueRepository.deleteItem(id: item.id)
        } catch {
            Logger.network.warning("SyncService: failed to clean up nutrition sync queue item \(item.id): \(error)")
        }
    }

    private func processFitnessSnapshotSync(_ item: SyncQueueItem) async throws {
        do {
            try await queueRepository.deleteItem(id: item.id)
        } catch {
            Logger.network.warning("SyncService: failed to clean up fitness sync queue item \(item.id): \(error)")
        }
    }

    private func processFinishEstimateSync(_ item: SyncQueueItem) async throws {
        do {
            try await queueRepository.deleteItem(id: item.id)
        } catch {
            Logger.network.warning("SyncService: failed to clean up finish estimate sync queue item \(item.id): \(error)")
        }
    }
}
