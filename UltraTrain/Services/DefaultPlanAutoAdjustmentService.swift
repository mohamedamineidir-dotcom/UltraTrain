import Foundation
import os

final class DefaultPlanAutoAdjustmentService: PlanAutoAdjustmentService {

    private let planGenerator: any GenerateTrainingPlanUseCase
    private let planRepository: any TrainingPlanRepository

    init(
        planGenerator: any GenerateTrainingPlanUseCase,
        planRepository: any TrainingPlanRepository
    ) {
        self.planGenerator = planGenerator
        self.planRepository = planRepository
    }

    func adjustPlanIfNeeded(
        currentPlan: TrainingPlan,
        currentRaces: [Race],
        athlete: Athlete,
        targetRace: Race
    ) async throws -> TrainingPlan? {
        let currentSnapshots = currentRaces
            .map { RaceSnapshot(id: $0.id, date: $0.date, priority: $0.priority) }
            .sorted { $0.id.uuidString < $1.id.uuidString }
        let planSnapshots = currentPlan.intermediateRaceSnapshots
            .sorted { $0.id.uuidString < $1.id.uuidString }

        guard currentSnapshots != planSnapshots else { return nil }

        Logger.training.info("Auto-adjusting plan: intermediate races changed")

        let oldProgress = PlanProgressPreserver.snapshot(currentPlan)

        var newPlan = try await planGenerator.execute(
            athlete: athlete,
            targetRace: targetRace,
            intermediateRaces: currentRaces
        )

        PlanProgressPreserver.restore(oldProgress, into: &newPlan)

        try await planRepository.savePlan(newPlan)

        for week in newPlan.weeks {
            for session in week.sessions where session.isCompleted || session.isSkipped || session.linkedRunId != nil {
                try await planRepository.updateSession(session)
            }
        }

        Logger.training.info("Plan auto-adjusted: \(newPlan.weeks.count) weeks")
        return newPlan
    }
}
