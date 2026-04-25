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

        let intermediatesChanged = currentSnapshots != planSnapshots

        // Target race date moved to a different week — trigger rebuild.
        // The plan's last week ends on the Sunday of the original race
        // week (WeekSkeletonBuilder anchors to that Monday). If the
        // current target race lands in a different week than the plan
        // was originally built for, the plan is structurally stale and
        // the schedule must rebuild around the new date.
        let raceWeekChanged: Bool = {
            guard let planLastWeekEnd = currentPlan.weeks.last?.endDate else { return false }
            let calendar = Calendar.current
            let planComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: planLastWeekEnd)
            let raceComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetRace.date)
            return planComponents.yearForWeekOfYear != raceComponents.yearForWeekOfYear
                || planComponents.weekOfYear != raceComponents.weekOfYear
        }()

        guard intermediatesChanged || raceWeekChanged else { return nil }

        let reason = raceWeekChanged
            ? (intermediatesChanged ? "race date + intermediates changed" : "race date changed")
            : "intermediate races changed"
        Logger.training.info("Auto-adjusting plan: \(reason)")

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
