import Foundation
import os

final class SyncedTrainingPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    private let local: LocalTrainingPlanRepository
    private let syncService: TrainingPlanSyncService

    init(local: LocalTrainingPlanRepository, syncService: TrainingPlanSyncService) {
        self.local = local
        self.syncService = syncService
    }

    func getActivePlan() async throws -> TrainingPlan? {
        try await local.getActivePlan()
    }

    func getPlan(id: UUID) async throws -> TrainingPlan? {
        try await local.getPlan(id: id)
    }

    func savePlan(_ plan: TrainingPlan) async throws {
        try await local.savePlan(plan)
        Task {
            await syncService.syncPlan(plan)
        }
    }

    func updatePlan(_ plan: TrainingPlan) async throws {
        try await local.updatePlan(plan)
        Task {
            await syncService.syncPlan(plan)
        }
    }

    func updateSession(_ session: TrainingSession) async throws {
        try await local.updateSession(session)
    }
}
