import Foundation
import os

final class SyncedTrainingPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    private let local: LocalTrainingPlanRepository
    private let syncService: TrainingPlanSyncService
    private let syncQueue: (any SyncQueueServiceProtocol)?

    init(
        local: LocalTrainingPlanRepository,
        syncService: TrainingPlanSyncService,
        syncQueue: (any SyncQueueServiceProtocol)? = nil
    ) {
        self.local = local
        self.syncService = syncService
        self.syncQueue = syncQueue
    }

    func getActivePlan() async throws -> TrainingPlan? {
        if let localPlan = try await local.getActivePlan() {
            return localPlan
        }
        return await restoreFromRemoteIfNeeded()
    }

    private func restoreFromRemoteIfNeeded() async -> TrainingPlan? {
        guard let plan = await syncService.restorePlan() else { return nil }
        do {
            try await local.savePlan(plan)
            Logger.persistence.info("SyncedTrainingPlanRepository: restored plan from server")
            return plan
        } catch {
            Logger.persistence.error("SyncedTrainingPlanRepository: failed to save restored plan: \(error)")
            return nil
        }
    }

    func getPlan(id: UUID) async throws -> TrainingPlan? {
        try await local.getPlan(id: id)
    }

    func savePlan(_ plan: TrainingPlan) async throws {
        try await local.savePlan(plan)
        if let queue = syncQueue {
            try? await queue.enqueueOperation(.trainingPlanSync, entityId: plan.id)
        } else {
            Task { await syncService.syncPlan(plan) }
        }
    }

    func updatePlan(_ plan: TrainingPlan) async throws {
        try await local.updatePlan(plan)
        if let queue = syncQueue {
            try? await queue.enqueueOperation(.trainingPlanSync, entityId: plan.id)
        } else {
            Task { await syncService.syncPlan(plan) }
        }
    }

    func updateSession(_ session: TrainingSession) async throws {
        try await local.updateSession(session)
    }
}
