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
