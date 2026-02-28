import Foundation
import os

final class FinishEstimateSyncService: @unchecked Sendable {
    private let remote: RemoteFinishEstimateDataSource
    private let authService: any AuthServiceProtocol

    init(remote: RemoteFinishEstimateDataSource, authService: any AuthServiceProtocol) {
        self.remote = remote
        self.authService = authService
    }

    func syncEstimate(_ estimate: FinishEstimate) async {
        guard authService.isAuthenticated() else { return }
        guard let dto = FinishEstimateRemoteMapper.toUploadDTO(estimate) else {
            Logger.network.error("FinishEstimateSyncService: failed to map estimate to DTO")
            return
        }
        do {
            _ = try await remote.upsertEstimate(dto)
            Logger.network.info("FinishEstimateSyncService: synced estimate \(estimate.id)")
        } catch {
            Logger.network.warning("FinishEstimateSyncService: sync failed: \(error)")
        }
    }

    func restoreEstimates() async -> [FinishEstimate] {
        guard authService.isAuthenticated() else { return [] }
        do {
            var allResponses: [FinishEstimateResponseDTO] = []
            var cursor: String? = nil
            repeat {
                let page = try await remote.fetchEstimates(cursor: cursor, limit: 100)
                allResponses.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            let estimates = allResponses.compactMap { FinishEstimateRemoteMapper.toDomain(from: $0) }
            Logger.network.info("FinishEstimateSyncService: restored \(estimates.count) estimates from server")
            return estimates
        } catch {
            Logger.network.info("FinishEstimateSyncService: no remote estimates to restore: \(error)")
            return []
        }
    }
}
