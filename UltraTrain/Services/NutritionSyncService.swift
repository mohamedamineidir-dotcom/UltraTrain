import Foundation
import os

final class NutritionSyncService: @unchecked Sendable {
    private let remote: RemoteNutritionDataSource
    private let authService: any AuthServiceProtocol

    init(remote: RemoteNutritionDataSource, authService: any AuthServiceProtocol) {
        self.remote = remote
        self.authService = authService
    }

    func syncNutrition(_ plan: NutritionPlan) async {
        guard authService.isAuthenticated() else { return }
        guard let dto = NutritionRemoteMapper.toUploadDTO(plan) else {
            Logger.network.error("NutritionSyncService: failed to map plan to DTO")
            return
        }
        do {
            _ = try await remote.upsertNutrition(dto)
            Logger.network.info("NutritionSyncService: synced nutrition plan \(plan.id)")
        } catch {
            Logger.network.warning("NutritionSyncService: sync failed: \(error)")
        }
    }

    func restoreNutrition() async -> [NutritionPlan] {
        guard authService.isAuthenticated() else { return [] }
        do {
            var allResponses: [NutritionResponseDTO] = []
            var cursor: String? = nil
            repeat {
                let page = try await remote.fetchNutrition(cursor: cursor, limit: 100)
                allResponses.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            let plans = allResponses.compactMap { NutritionRemoteMapper.toDomain(from: $0) }
            Logger.network.info("NutritionSyncService: restored \(plans.count) nutrition plans from server")
            return plans
        } catch {
            Logger.network.info("NutritionSyncService: no remote nutrition to restore: \(error)")
            return []
        }
    }
}
