#if DEBUG
import SwiftUI

private struct PreviewPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    func getActivePlan() async throws -> TrainingPlan? { nil }
    func getPlan(id: UUID) async throws -> TrainingPlan? { nil }
    func savePlan(_ plan: TrainingPlan) async throws {}
    func updatePlan(_ plan: TrainingPlan) async throws {}
    func updateSession(_ session: TrainingSession) async throws {}
}

private struct PreviewRunRepository: RunRepository, @unchecked Sendable {
    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] { [] }
    func getRun(id: UUID) async throws -> CompletedRun? { nil }
    func saveRun(_ run: CompletedRun) async throws {}
    func deleteRun(id: UUID) async throws {}
    func updateRun(_ run: CompletedRun) async throws {}
    func updateLinkedSession(runId: UUID, sessionId: UUID) async throws {}
    func getRecentRuns(limit: Int) async throws -> [CompletedRun] { [] }
}

private struct PreviewAthleteRepository: AthleteRepository, @unchecked Sendable {
    func getAthlete() async throws -> Athlete? { nil }
    func saveAthlete(_ athlete: Athlete) async throws {}
    func updateAthlete(_ athlete: Athlete) async throws {}
}

private struct PreviewFitnessRepository: FitnessRepository, @unchecked Sendable {
    func getSnapshots(from: Date, to: Date) async throws -> [FitnessSnapshot] { [] }
    func getLatestSnapshot() async throws -> FitnessSnapshot? { nil }
    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws {}
}

private struct PreviewFitnessCalculator: CalculateFitnessUseCase, @unchecked Sendable {
    func execute(runs: [CompletedRun], asOf date: Date) async throws -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: 0,
            fatigue: 0,
            form: 0,
            weeklyVolumeKm: 0,
            weeklyElevationGainM: 0,
            weeklyDuration: 0,
            acuteToChronicRatio: 0,
            monotony: 0
        )
    }
}

private struct PreviewTrainingLoadCalculator: CalculateTrainingLoadUseCase, @unchecked Sendable {
    func execute(runs: [CompletedRun], plan: TrainingPlan?, asOf date: Date) async throws -> TrainingLoadSummary {
        TrainingLoadSummary(
            currentWeekLoad: WeeklyLoadData(weekStartDate: date.startOfWeek),
            weeklyHistory: [], acrTrend: [], monotony: 0, monotonyLevel: .low
        )
    }
}

private struct PreviewRaceRepository: RaceRepository, @unchecked Sendable {
    func getRaces() async throws -> [Race] { [] }
    func getRace(id: UUID) async throws -> Race? { nil }
    func saveRace(_ race: Race) async throws {}
    func updateRace(_ race: Race) async throws {}
    func deleteRace(id: UUID) async throws {}
}

private struct PreviewFinishTimeEstimator: EstimateFinishTimeUseCase, @unchecked Sendable {
    func execute(athlete: Athlete, race: Race, recentRuns: [CompletedRun], currentFitness: FitnessSnapshot?, pastRaceCalibrations: [RaceCalibration]) async throws -> FinishEstimate {
        FinishEstimate(
            id: UUID(), raceId: race.id, athleteId: athlete.id, calculatedAt: .now,
            optimisticTime: 0, expectedTime: 0, conservativeTime: 0,
            checkpointSplits: [], confidencePercent: 0, raceResultsUsed: 0
        )
    }
}

private struct PreviewFinishEstimateRepository: FinishEstimateRepository, @unchecked Sendable {
    func getEstimate(for raceId: UUID) async throws -> FinishEstimate? { nil }
    func saveEstimate(_ estimate: FinishEstimate) async throws {}
}

private struct PreviewNutritionRepository: NutritionRepository, @unchecked Sendable {
    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan? { nil }
    func saveNutritionPlan(_ plan: NutritionPlan) async throws {}
    func updateNutritionPlan(_ plan: NutritionPlan) async throws {}
    func getProducts() async throws -> [NutritionProduct] { [] }
    func saveProduct(_ product: NutritionProduct) async throws {}
    func getNutritionPreferences() async throws -> NutritionPreferences { .default }
    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws {}
}

private struct PreviewNutritionGenerator: GenerateNutritionPlanUseCase, @unchecked Sendable {
    func execute(athlete: Athlete, race: Race, estimatedDuration: TimeInterval, preferences: NutritionPreferences) async throws -> NutritionPlan {
        NutritionPlan(id: UUID(), raceId: race.id, caloriesPerHour: 0, hydrationMlPerHour: 0, sodiumMgPerHour: 0, entries: [], gutTrainingSessionIds: [])
    }
}

#Preview("Dashboard") {
    DashboardView(
        selectedTab: .constant(.dashboard),
        planRepository: PreviewPlanRepository(),
        runRepository: PreviewRunRepository(),
        athleteRepository: PreviewAthleteRepository(),
        fitnessRepository: PreviewFitnessRepository(),
        fitnessCalculator: PreviewFitnessCalculator(),
        trainingLoadCalculator: PreviewTrainingLoadCalculator(),
        raceRepository: PreviewRaceRepository(),
        finishTimeEstimator: PreviewFinishTimeEstimator(),
        finishEstimateRepository: PreviewFinishEstimateRepository(),
        nutritionRepository: PreviewNutritionRepository(),
        nutritionGenerator: PreviewNutritionGenerator()
    )
}
#endif
