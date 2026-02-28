import Foundation
import os

final class SyncedFitnessRepository: FitnessRepository, @unchecked Sendable {
    private let local: LocalFitnessRepository
    private let syncService: FitnessSyncService
    private var hasAttemptedRestore = false

    init(local: LocalFitnessRepository, syncService: FitnessSyncService) {
        self.local = local
        self.syncService = syncService
    }

    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [FitnessSnapshot] {
        let snapshots = try await local.getSnapshots(from: startDate, to: endDate)
        if snapshots.isEmpty {
            return await restoreIfNeeded(from: startDate, to: endDate)
        }
        return snapshots
    }

    func getLatestSnapshot() async throws -> FitnessSnapshot? {
        try await local.getLatestSnapshot()
    }

    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws {
        try await local.saveSnapshot(snapshot)
        Task { await syncService.syncSnapshot(snapshot) }
    }

    private func restoreIfNeeded(from startDate: Date, to endDate: Date) async -> [FitnessSnapshot] {
        guard !hasAttemptedRestore else { return [] }
        hasAttemptedRestore = true
        let snapshots = await syncService.restoreSnapshots()
        guard !snapshots.isEmpty else { return [] }
        for snapshot in snapshots {
            try? await local.saveSnapshot(snapshot)
        }
        Logger.network.info("SyncedFitnessRepository: restored \(snapshots.count) snapshots")
        return snapshots.filter { $0.date >= startDate && $0.date <= endDate }
    }
}
