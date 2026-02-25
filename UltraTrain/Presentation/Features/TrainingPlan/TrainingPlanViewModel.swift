import Foundation
import os

@Observable
@MainActor
final class TrainingPlanViewModel {

    // MARK: - Dependencies

    let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    let nutritionAdvisor: any SessionNutritionAdvisor
    let fitnessRepository: any FitnessRepository
    let widgetDataWriter: WidgetDataWriter

    // MARK: - State

    var plan: TrainingPlan?
    var races: [Race] = []
    var athlete: Athlete?
    var nutritionPreferences: NutritionPreferences = .default
    var isLoading = false
    var isGenerating = false
    var error: String?
    var showRegenerateConfirmation = false
    var adjustmentRecommendations: [PlanAdjustmentRecommendation] = []
    var dismissedRecommendationIds: Set<UUID> = []
    var isApplyingAdjustment = false

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionAdvisor: any SessionNutritionAdvisor,
        fitnessRepository: any FitnessRepository,
        widgetDataWriter: WidgetDataWriter
    ) {
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionAdvisor = nutritionAdvisor
        self.fitnessRepository = fitnessRepository
        self.widgetDataWriter = widgetDataWriter
    }

    // MARK: - Load

    func loadPlan() async {
        isLoading = true
        error = nil

        do {
            plan = try await planRepository.getActivePlan()
            races = try await raceRepository.getRaces()
            athlete = try await athleteRepository.getAthlete()
            nutritionPreferences = try await nutritionRepository.getNutritionPreferences()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load plan: \(error)")
        }

        isLoading = false
        checkForAdjustments()
    }

    // MARK: - Refresh Races

    func refreshRaces() async {
        do {
            races = try await raceRepository.getRaces()
        } catch {
            Logger.training.error("Failed to refresh races: \(error)")
        }
    }

    // MARK: - Generate

    func generatePlan() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                throw DomainError.athleteNotFound
            }

            let allRaces = try await raceRepository.getRaces()
            guard let targetRace = allRaces.first(where: { $0.priority == .aRace }) else {
                throw DomainError.raceNotFound
            }

            let intermediateRaces = allRaces.filter { $0.priority != .aRace && $0.date < targetRace.date }

            // Snapshot old session progress before regenerating
            let oldProgress = plan.map { PlanProgressPreserver.snapshot($0) } ?? []

            var newPlan = try await planGenerator.execute(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces
            )

            // Restore progress from old plan to matching sessions
            PlanProgressPreserver.restore(oldProgress, into: &newPlan)

            try await planRepository.savePlan(newPlan)

            // Persist restored session statuses
            for week in newPlan.weeks {
                for session in week.sessions where session.isCompleted || session.isSkipped || session.linkedRunId != nil {
                    try await planRepository.updateSession(session)
                }
            }

            plan = newPlan
            self.athlete = athlete
            races = allRaces
            Logger.training.info("Plan generated: \(newPlan.weeks.count) weeks")
            await updateWidgets()
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to generate plan: \(error)")
        }

        isGenerating = false
    }

    // MARK: - Computed

    var currentWeek: TrainingWeek? {
        plan?.weeks.first { $0.containsToday }
    }

    var nextSession: TrainingSession? {
        guard let week = currentWeek else { return nil }
        let now = Date.now.startOfDay
        return week.sessions
            .filter { !$0.isCompleted && !$0.isSkipped && $0.date >= now && $0.type != .rest }
            .sorted { $0.date < $1.date }
            .first
    }

    var weeklyProgress: (completed: Int, total: Int) {
        guard let week = currentWeek else { return (0, 0) }
        let activeSessions = week.sessions.filter { $0.type != .rest && !$0.isSkipped }
        let completed = activeSessions.filter(\.isCompleted).count
        return (completed, activeSessions.count)
    }

    var targetRace: Race? {
        races.first { $0.priority == .aRace }
    }

    var isPlanStale: Bool {
        guard let plan, let target = targetRace else { return false }
        let currentIntermediates = races
            .filter { $0.priority != .aRace && $0.date < target.date }

        // Use snapshots for comparison when available (detects date + priority changes)
        if !plan.intermediateRaceSnapshots.isEmpty {
            let currentSnapshots = currentIntermediates
                .map { RaceSnapshot(id: $0.id, date: $0.date, priority: $0.priority) }
                .sorted { $0.id.uuidString < $1.id.uuidString }
            let planSnapshots = plan.intermediateRaceSnapshots
                .sorted { $0.id.uuidString < $1.id.uuidString }
            return currentSnapshots != planSnapshots
        }

        // Fallback for old plans without snapshots — UUID-only comparison
        let currentIds = currentIntermediates
            .map(\.id)
            .sorted { $0.uuidString < $1.uuidString }
        let planIds = plan.intermediateRaceIds
            .sorted { $0.uuidString < $1.uuidString }
        return currentIds != planIds
    }

    var raceChangeSummary: (added: [Race], removed: [UUID]) {
        guard let plan, let target = targetRace else { return ([], []) }
        let currentIntermediates = races.filter { $0.priority != .aRace && $0.date < target.date }
        let currentIds = Set(currentIntermediates.map(\.id))
        let planIds = Set(plan.intermediateRaceIds)

        let added = currentIntermediates.filter { !planIds.contains($0.id) }
        let removed = plan.intermediateRaceIds.filter { !currentIds.contains($0) }
        return (added, removed)
    }

    // MARK: - Widgets

    func updateWidgets() async {
        await widgetDataWriter.writeNextSession()
        await widgetDataWriter.writeWeeklyProgress()
        widgetDataWriter.reloadWidgets()
    }
}
