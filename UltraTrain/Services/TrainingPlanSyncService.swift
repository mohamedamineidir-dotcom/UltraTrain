import Foundation
import os

final class TrainingPlanSyncService: @unchecked Sendable {
    private let remote: RemoteTrainingPlanDataSource
    private let raceRepository: any RaceRepository
    private let authService: any AuthServiceProtocol

    init(
        remote: RemoteTrainingPlanDataSource,
        raceRepository: any RaceRepository,
        authService: any AuthServiceProtocol
    ) {
        self.remote = remote
        self.raceRepository = raceRepository
        self.authService = authService
    }

    func restorePlan() async -> TrainingPlan? {
        guard authService.isAuthenticated() else { return nil }

        do {
            let response = try await remote.fetchPlan()
            guard let plan = TrainingPlanRemoteMapper.toDomain(from: response) else {
                Logger.network.warning("TrainingPlanSyncService: failed to decode remote plan")
                return nil
            }
            Logger.network.info("TrainingPlanSyncService: restored plan \(plan.id) from server")
            return plan
        } catch {
            Logger.network.info("TrainingPlanSyncService: no remote plan to restore: \(error)")
            return nil
        }
    }

    func syncPlan(_ plan: TrainingPlan) async {
        guard authService.isAuthenticated() else { return }

        do {
            let race = try await raceRepository.getRace(id: plan.targetRaceId)
            let raceName = race?.name ?? "Unknown Race"
            let raceDate = race?.date ?? Date()

            guard let dto = TrainingPlanRemoteMapper.toUploadDTO(
                plan: plan,
                raceName: raceName,
                raceDate: raceDate
            ) else {
                Logger.network.error("TrainingPlanSyncService: failed to map plan to DTO")
                return
            }

            _ = try await remote.uploadPlan(dto)
            Logger.network.info("TrainingPlanSyncService: uploaded plan \(plan.id)")
        } catch {
            Logger.network.warning("TrainingPlanSyncService: sync failed: \(error)")
        }
    }
}
