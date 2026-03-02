import Foundation
import os

// @unchecked Sendable: mutable timestamp only written from async context
final class SyncedFitnessRepository: FitnessRepository, @unchecked Sendable {
    private let local: LocalFitnessRepository
    private let syncService: FitnessSyncService
    private var lastRestoreAttempt: Date?
    private let restoreTTL: TimeInterval = 86400

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
        if let last = lastRestoreAttempt, Date().timeIntervalSince(last) < restoreTTL { return [] }
        lastRestoreAttempt = Date()
        let snapshots = await syncService.restoreSnapshots()
        guard !snapshots.isEmpty else { return [] }
        for snapshot in snapshots {
            do {
                try await local.saveSnapshot(snapshot)
            } catch {
                Logger.persistence.warning("SyncedFitnessRepository: failed to save restored snapshot for \(snapshot.date): \(error)")
            }
        }
        Logger.network.info("SyncedFitnessRepository: restored \(snapshots.count) snapshots")
        return snapshots.filter { $0.date >= startDate && $0.date <= endDate }
    }
}
