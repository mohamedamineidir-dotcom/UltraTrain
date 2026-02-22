import Foundation
import os

final class SyncedRunRepository: RunRepository, @unchecked Sendable {
    private let local: LocalRunRepository
    private let syncService: SyncService

    init(local: LocalRunRepository, syncService: SyncService) {
        self.local = local
        self.syncService = syncService
    }

    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] {
        try await local.getRuns(for: athleteId)
    }

    func getRun(id: UUID) async throws -> CompletedRun? {
        try await local.getRun(id: id)
    }

    func getRecentRuns(limit: Int) async throws -> [CompletedRun] {
        try await local.getRecentRuns(limit: limit)
    }

    func saveRun(_ run: CompletedRun) async throws {
        try await local.saveRun(run)
        await syncService.enqueueRunUpload(runId: run.id)
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
