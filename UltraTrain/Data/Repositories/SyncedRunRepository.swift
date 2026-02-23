import Foundation
import os

final class SyncedRunRepository: RunRepository, @unchecked Sendable {
    private let local: LocalRunRepository
    private let syncService: any SyncQueueServiceProtocol
    private let restoreService: RunRestoreService?
    private let remoteDataSource: RemoteRunDataSource?
    private let authService: (any AuthServiceProtocol)?
    private var hasAttemptedRestore = false

    init(
        local: LocalRunRepository,
        syncService: any SyncQueueServiceProtocol,
        restoreService: RunRestoreService? = nil,
        remoteDataSource: RemoteRunDataSource? = nil,
        authService: (any AuthServiceProtocol)? = nil
    ) {
        self.local = local
        self.syncService = syncService
        self.restoreService = restoreService
        self.remoteDataSource = remoteDataSource
        self.authService = authService
    }

    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] {
        let localRuns = try await local.getRuns(for: athleteId)
        if localRuns.isEmpty, let restored = await restoreRunsIfNeeded() {
            return restored
        }
        return localRuns
    }

    func getRun(id: UUID) async throws -> CompletedRun? {
        try await local.getRun(id: id)
    }

    func getRecentRuns(limit: Int) async throws -> [CompletedRun] {
        let localRuns = try await local.getRecentRuns(limit: limit)
        if localRuns.isEmpty, let restored = await restoreRunsIfNeeded() {
            return Array(restored.prefix(limit))
        }
        return localRuns
    }

    private func restoreRunsIfNeeded() async -> [CompletedRun]? {
        guard let restoreService, !hasAttemptedRestore else { return nil }
        hasAttemptedRestore = true
        let runs = await restoreService.restoreRuns()
        guard !runs.isEmpty else { return nil }
        for run in runs {
            try? await local.saveRun(run)
        }
        Logger.network.info("SyncedRunRepository: saved \(runs.count) restored runs locally")
        return runs
    }

    func saveRun(_ run: CompletedRun) async throws {
        try await local.saveRun(run)
        try await syncService.enqueueUpload(runId: run.id)
    }

    func updateRun(_ run: CompletedRun) async throws {
        try await local.updateRun(run)
        if let remote = remoteDataSource, authService?.isAuthenticated() == true {
            Task {
                do {
                    let dto = RunMapper.toUploadDTO(run)
                    _ = try await remote.updateRun(dto, id: run.id)
                } catch {
                    Logger.network.warning("Remote run update failed: \(error)")
                }
            }
        }
    }

    func deleteRun(id: UUID) async throws {
        try await local.deleteRun(id: id)
        if let remote = remoteDataSource, authService?.isAuthenticated() == true {
            Task {
                do {
                    try await remote.deleteRun(id: id)
                } catch {
                    Logger.network.warning("Remote run deletion failed: \(error)")
                }
            }
        }
    }

    func updateLinkedSession(runId: UUID, sessionId: UUID) async throws {
        try await local.updateLinkedSession(runId: runId, sessionId: sessionId)
    }
}
