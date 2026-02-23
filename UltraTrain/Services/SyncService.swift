import Foundation
import os

final class SyncService: SyncQueueServiceProtocol, @unchecked Sendable {
    private let queueRepository: any SyncQueueRepository
    private let localRunRepository: LocalRunRepository
    private let remoteRunDataSource: RemoteRunDataSource
    private let authService: any AuthServiceProtocol

    init(
        queueRepository: any SyncQueueRepository,
        localRunRepository: LocalRunRepository,
        remoteRunDataSource: RemoteRunDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.queueRepository = queueRepository
        self.localRunRepository = localRunRepository
        self.remoteRunDataSource = remoteRunDataSource
        self.authService = authService
    }

    func enqueueUpload(runId: UUID) async throws {
        if let existing = try await queueRepository.getItem(forRunId: runId) {
            if existing.status == .completed { return }
            var reset = existing
            reset.status = .pending
            reset.retryCount = 0
            reset.errorMessage = nil
            try await queueRepository.updateItem(reset)
        } else {
            let item = SyncQueueItem(
                id: UUID(),
                runId: runId,
                status: .pending,
                retryCount: 0,
                lastAttempt: nil,
                errorMessage: nil,
                createdAt: Date()
            )
            try await queueRepository.saveItem(item)
        }
        Logger.network.info("SyncService: queued run \(runId) for upload")
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
            guard let run = try await localRunRepository.getRun(id: item.runId) else {
                try? await queueRepository.deleteItem(id: item.id)
                Logger.network.info("SyncService: run \(item.runId) not found, removed from queue")
                return
            }

            let dto = RunMapper.toUploadDTO(run)
            _ = try await remoteRunDataSource.uploadRun(dto)

            mutable.status = .completed
            try? await queueRepository.updateItem(mutable)
            Logger.network.info("SyncService: uploaded run \(item.runId)")
        } catch let error as APIError {
            switch error {
            case .clientError, .unauthorized, .invalidURL, .decodingError:
                mutable.status = .failed
                mutable.retryCount = 5
                mutable.errorMessage = error.localizedDescription
                Logger.network.error("SyncService: permanent failure for run \(item.runId): \(error)")
            default:
                mutable.retryCount += 1
                mutable.errorMessage = error.localizedDescription
                mutable.status = mutable.hasReachedMaxRetries ? .failed : .pending
                Logger.network.warning("SyncService: retryable failure for run \(item.runId) (attempt \(mutable.retryCount)): \(error)")
            }
            try? await queueRepository.updateItem(mutable)
        } catch {
            mutable.retryCount += 1
            mutable.errorMessage = error.localizedDescription
            mutable.status = mutable.hasReachedMaxRetries ? .failed : .pending
            try? await queueRepository.updateItem(mutable)
            Logger.network.warning("SyncService: upload error for run \(item.runId): \(error)")
        }
    }
}
