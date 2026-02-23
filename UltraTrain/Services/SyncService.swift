import Foundation
import os

final class SyncService: SyncQueueServiceProtocol, @unchecked Sendable {
    private let queueRepository: any SyncQueueRepository
    private let localRunRepository: LocalRunRepository
    private let remoteRunDataSource: RemoteRunDataSource
    private let authService: any AuthServiceProtocol
    private let remoteAthleteDataSource: RemoteAthleteDataSource?
    private let localAthleteRepository: (any AthleteRepository)?
    private let remoteRaceDataSource: RemoteRaceDataSource?
    private let localRaceRepository: (any RaceRepository)?
    private let remoteTrainingPlanDataSource: RemoteTrainingPlanDataSource?
    private let localTrainingPlanRepository: (any TrainingPlanRepository)?
    private let trainingPlanSyncService: TrainingPlanSyncService?

    init(
        queueRepository: any SyncQueueRepository,
        localRunRepository: LocalRunRepository,
        remoteRunDataSource: RemoteRunDataSource,
        authService: any AuthServiceProtocol,
        remoteAthleteDataSource: RemoteAthleteDataSource? = nil,
        localAthleteRepository: (any AthleteRepository)? = nil,
        remoteRaceDataSource: RemoteRaceDataSource? = nil,
        localRaceRepository: (any RaceRepository)? = nil,
        remoteTrainingPlanDataSource: RemoteTrainingPlanDataSource? = nil,
        localTrainingPlanRepository: (any TrainingPlanRepository)? = nil,
        trainingPlanSyncService: TrainingPlanSyncService? = nil
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
        try? await queueRepository.getItem(forRunId: runId)?.status
    }

    func getPendingCount() async -> Int {
        (try? await queueRepository.getPendingCount()) ?? 0
    }

    func getFailedCount() async -> Int {
        (try? await queueRepository.getFailedCount()) ?? 0
    }

    // MARK: - Private

    private func processItem(_ item: SyncQueueItem) async {
        var mutable = item
        mutable.status = .uploading
        mutable.lastAttempt = Date()
        try? await queueRepository.updateItem(mutable)

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
            }

            mutable.status = .completed
            try? await queueRepository.updateItem(mutable)
            Logger.network.info("SyncService: completed \(item.operationType.rawValue) for \(item.entityId)")
        } catch let error as APIError {
            switch error {
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
            try? await queueRepository.updateItem(mutable)
        } catch {
            mutable.retryCount += 1
            mutable.errorMessage = error.localizedDescription
            mutable.status = mutable.hasReachedMaxRetries ? .failed : .pending
            try? await queueRepository.updateItem(mutable)
            Logger.network.warning("SyncService: error for \(item.operationType.rawValue) \(item.entityId): \(error)")
        }
    }

    private func processRunUpload(_ item: SyncQueueItem) async throws {
        guard let run = try await localRunRepository.getRun(id: item.entityId) else {
            try? await queueRepository.deleteItem(id: item.id)
            Logger.network.info("SyncService: run \(item.entityId) not found, removed from queue")
            return
        }
        let dto = RunMapper.toUploadDTO(run)
        _ = try await remoteRunDataSource.uploadRun(dto)
    }

    private func processAthleteSync(_ item: SyncQueueItem) async throws {
        guard let repo = localAthleteRepository,
              let remote = remoteAthleteDataSource else { return }
        guard let athlete = try await repo.getAthlete() else {
            try? await queueRepository.deleteItem(id: item.id)
            return
        }
        let dto = AthleteMapper.toDTO(athlete)
        _ = try await remote.updateAthlete(dto)
    }

    private func processRaceSync(_ item: SyncQueueItem) async throws {
        guard let repo = localRaceRepository,
              let remote = remoteRaceDataSource else { return }
        guard let race = try await repo.getRace(id: item.entityId) else {
            try? await queueRepository.deleteItem(id: item.id)
            return
        }
        guard let dto = RaceRemoteMapper.toUploadDTO(race) else { return }
        _ = try await remote.upsertRace(dto)
    }

    private func processRaceDelete(_ item: SyncQueueItem) async throws {
        guard let remote = remoteRaceDataSource else { return }
        try await remote.deleteRace(id: item.entityId.uuidString)
    }

    private func processTrainingPlanSync(_ item: SyncQueueItem) async throws {
        guard let repo = localTrainingPlanRepository,
              let syncService = trainingPlanSyncService else { return }
        guard let plan = try await repo.getActivePlan() else {
            try? await queueRepository.deleteItem(id: item.id)
            return
        }
        await syncService.syncPlan(plan)
    }
}
