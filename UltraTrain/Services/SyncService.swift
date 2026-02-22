import Foundation
import os

final class SyncService: @unchecked Sendable {
    private let localRunRepository: LocalRunRepository
    private let remoteRunDataSource: RemoteRunDataSource
    private let authService: any AuthServiceProtocol

    private var pendingRunIds: Set<UUID> = []
    private let lock = NSLock()

    init(
        localRunRepository: LocalRunRepository,
        remoteRunDataSource: RemoteRunDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.localRunRepository = localRunRepository
        self.remoteRunDataSource = remoteRunDataSource
        self.authService = authService
    }

    func enqueueRunUpload(runId: UUID) async {
        addToQueue(id: runId)
        Logger.network.info("SyncService: queued run \(runId) for upload")
        await processQueue()
    }

    func processQueue() async {
        guard authService.isAuthenticated() else { return }

        let ids = copyQueue()

        for id in ids {
            await uploadRun(id: id)
        }
    }

    // MARK: - Synchronous Lock Helpers

    private func addToQueue(id: UUID) {
        lock.withLock { _ = pendingRunIds.insert(id) }
    }

    private func copyQueue() -> Set<UUID> {
        lock.withLock { pendingRunIds }
    }

    private func removeFromQueue(id: UUID) {
        lock.withLock { _ = pendingRunIds.remove(id) }
    }

    // MARK: - Private

    private func uploadRun(id: UUID) async {
        do {
            guard let run = try await localRunRepository.getRun(id: id) else {
                removeFromQueue(id: id)
                return
            }

            let dto = RunMapper.toUploadDTO(run)
            _ = try await remoteRunDataSource.uploadRun(dto)
            removeFromQueue(id: id)
            Logger.network.info("SyncService: uploaded run \(id)")
        } catch let error as APIError {
            if case .clientError = error {
                removeFromQueue(id: id)
                Logger.network.error("SyncService: permanent failure for run \(id): \(error)")
            } else {
                Logger.network.warning("SyncService: upload failed for run \(id), will retry: \(error)")
            }
        } catch {
            Logger.network.warning("SyncService: upload error for run \(id): \(error)")
        }
    }
}
