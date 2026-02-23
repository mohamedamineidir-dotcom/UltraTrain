import Foundation
import os

final class SyncedRunRepository: RunRepository, @unchecked Sendable {
    private let local: LocalRunRepository
    private let syncService: any SyncQueueServiceProtocol
    private let restoreService: RunRestoreService?
    private var hasAttemptedRestore = false

    init(
        local: LocalRunRepository,
        syncService: any SyncQueueServiceProtocol,
        restoreService: RunRestoreService? = nil
    ) {
        self.local = local
        self.syncService = syncService
        self.restoreService = restoreService
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
    }

    func deleteRun(id: UUID) async throws {
        try await local.deleteRun(id: id)
    }

    func updateLinkedSession(runId: UUID, sessionId: UUID) async throws {
        try await local.updateLinkedSession(runId: runId, sessionId: sessionId)
    }
}
