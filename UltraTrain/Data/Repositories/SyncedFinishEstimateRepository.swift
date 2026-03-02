import Foundation
import os

final class SyncedFinishEstimateRepository: FinishEstimateRepository, @unchecked Sendable {
    private let local: LocalFinishEstimateRepository
    private let syncService: FinishEstimateSyncService
    private var lastRestoreAttempt: Date?
    private let restoreTTL: TimeInterval = 86400

    init(local: LocalFinishEstimateRepository, syncService: FinishEstimateSyncService) {
        self.local = local
        self.syncService = syncService
    }

    func getEstimate(for raceId: UUID) async throws -> FinishEstimate? {
        if let estimate = try await local.getEstimate(for: raceId) {
            return estimate
        }
        return await restoreIfNeeded(raceId: raceId)
    }

    func saveEstimate(_ estimate: FinishEstimate) async throws {
        try await local.saveEstimate(estimate)
        Task { await syncService.syncEstimate(estimate) }
    }

    private func restoreIfNeeded(raceId: UUID) async -> FinishEstimate? {
        if let last = lastRestoreAttempt, Date().timeIntervalSince(last) < restoreTTL { return nil }
        lastRestoreAttempt = Date()
        let estimates = await syncService.restoreEstimates()
        guard !estimates.isEmpty else { return nil }
        for estimate in estimates {
            try? await local.saveEstimate(estimate)
        }
        Logger.network.info("SyncedFinishEstimateRepository: restored \(estimates.count) estimates")
        return estimates.first { $0.raceId == raceId }
    }
}
