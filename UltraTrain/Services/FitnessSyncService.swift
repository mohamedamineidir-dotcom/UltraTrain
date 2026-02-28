import Foundation
import os

final class FitnessSyncService: @unchecked Sendable {
    private let remote: RemoteFitnessDataSource
    private let authService: any AuthServiceProtocol

    init(remote: RemoteFitnessDataSource, authService: any AuthServiceProtocol) {
        self.remote = remote
        self.authService = authService
    }

    func syncSnapshot(_ snapshot: FitnessSnapshot) async {
        guard authService.isAuthenticated() else { return }
        guard let dto = FitnessRemoteMapper.toUploadDTO(snapshot) else {
            Logger.network.error("FitnessSyncService: failed to map snapshot to DTO")
            return
        }
        do {
            _ = try await remote.upsertSnapshot(dto)
            Logger.network.info("FitnessSyncService: synced fitness snapshot \(snapshot.id)")
        } catch {
            Logger.network.warning("FitnessSyncService: sync failed: \(error)")
        }
    }

    func restoreSnapshots() async -> [FitnessSnapshot] {
        guard authService.isAuthenticated() else { return [] }
        do {
            var allResponses: [FitnessSnapshotResponseDTO] = []
            var cursor: String? = nil
            repeat {
                let page = try await remote.fetchSnapshots(cursor: cursor, limit: 100)
                allResponses.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            let snapshots = allResponses.compactMap { FitnessRemoteMapper.toDomain(from: $0) }
            Logger.network.info("FitnessSyncService: restored \(snapshots.count) snapshots from server")
            return snapshots
        } catch {
            Logger.network.info("FitnessSyncService: no remote snapshots to restore: \(error)")
            return []
        }
    }
}
