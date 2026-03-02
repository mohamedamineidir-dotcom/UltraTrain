import Foundation
import os

// @unchecked Sendable: mutable timestamp only written from async context
final class SyncedNutritionRepository: NutritionRepository, @unchecked Sendable {
    private let local: LocalNutritionRepository
    private let syncService: NutritionSyncService
    private var lastRestoreAttempt: Date?
    private let restoreTTL: TimeInterval = 86400

    init(local: LocalNutritionRepository, syncService: NutritionSyncService) {
        self.local = local
        self.syncService = syncService
    }

    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan? {
        if let plan = try await local.getNutritionPlan(for: raceId) {
            return plan
        }
        return await restoreIfNeeded(raceId: raceId)
    }

    func saveNutritionPlan(_ plan: NutritionPlan) async throws {
        try await local.saveNutritionPlan(plan)
        Task { await syncService.syncNutrition(plan) }
    }

    func updateNutritionPlan(_ plan: NutritionPlan) async throws {
        try await local.updateNutritionPlan(plan)
        Task { await syncService.syncNutrition(plan) }
    }

    func getProducts() async throws -> [NutritionProduct] {
        try await local.getProducts()
    }

    func saveProduct(_ product: NutritionProduct) async throws {
        try await local.saveProduct(product)
    }

    func getNutritionPreferences() async throws -> NutritionPreferences {
        try await local.getNutritionPreferences()
    }

    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws {
        try await local.saveNutritionPreferences(preferences)
    }

    private func restoreIfNeeded(raceId: UUID) async -> NutritionPlan? {
        if let last = lastRestoreAttempt, Date().timeIntervalSince(last) < restoreTTL { return nil }
        lastRestoreAttempt = Date()
        let plans = await syncService.restoreNutrition()
        guard !plans.isEmpty else { return nil }
        for plan in plans {
            do {
                try await local.saveNutritionPlan(plan)
            } catch {
                Logger.persistence.warning("SyncedNutritionRepository: failed to save restored nutrition plan \(plan.id): \(error)")
            }
        }
        Logger.network.info("SyncedNutritionRepository: restored \(plans.count) nutrition plans")
        return plans.first { $0.raceId == raceId }
    }
}
