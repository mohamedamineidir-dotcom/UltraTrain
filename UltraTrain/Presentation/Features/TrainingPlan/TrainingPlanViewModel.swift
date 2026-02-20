import Foundation
import os

@Observable
@MainActor
final class TrainingPlanViewModel {

    // MARK: - Dependencies

    private let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    let nutritionAdvisor: any SessionNutritionAdvisor
    private let fitnessRepository: any FitnessRepository
    private let widgetDataWriter: WidgetDataWriter

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
    private var dismissedRecommendationIds: Set<UUID> = []
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

    // MARK: - Toggle Session

    func toggleSessionCompletion(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isCompleted.toggle()
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            await updateWidgets()
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to update session: \(error)")
        }
    }

    // MARK: - Skip

    func skipSession(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isSkipped = true
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to skip session: \(error)")
        }
    }

    func unskipSession(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isSkipped = false
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to unskip session: \(error)")
        }
    }

    // MARK: - Reschedule

    func rescheduleSession(weekIndex: Int, sessionIndex: Int, to newDate: Date) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.date = newDate
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session
        currentPlan.weeks[weekIndex].sessions.sort { $0.date < $1.date }

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to reschedule session: \(error)")
        }
    }

    // MARK: - Swap

    func swapSessions(
        weekIndexA: Int, sessionIndexA: Int,
        weekIndexB: Int, sessionIndexB: Int
    ) async {
        guard var currentPlan = plan else { return }
        guard weekIndexA < currentPlan.weeks.count,
              sessionIndexA < currentPlan.weeks[weekIndexA].sessions.count,
              weekIndexB < currentPlan.weeks.count,
              sessionIndexB < currentPlan.weeks[weekIndexB].sessions.count else { return }

        var sessionA = currentPlan.weeks[weekIndexA].sessions[sessionIndexA]
        var sessionB = currentPlan.weeks[weekIndexB].sessions[sessionIndexB]

        let dateA = sessionA.date
        sessionA.date = sessionB.date
        sessionB.date = dateA

        currentPlan.weeks[weekIndexA].sessions[sessionIndexA] = sessionA
        currentPlan.weeks[weekIndexB].sessions[sessionIndexB] = sessionB
        currentPlan.weeks[weekIndexA].sessions.sort { $0.date < $1.date }
        if weekIndexA != weekIndexB {
            currentPlan.weeks[weekIndexB].sessions.sort { $0.date < $1.date }
        }

        do {
            try await planRepository.updateSession(sessionA)
            try await planRepository.updateSession(sessionB)
            plan = currentPlan
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to swap sessions: \(error)")
        }
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

    // MARK: - Plan Adjustments

    var visibleRecommendations: [PlanAdjustmentRecommendation] {
        adjustmentRecommendations.filter { !dismissedRecommendationIds.contains($0.id) }
    }

    func checkForAdjustments() {
        guard let plan else {
            adjustmentRecommendations = []
            return
        }
        adjustmentRecommendations = PlanAdjustmentCalculator.analyze(plan: plan)
        let currentIds = Set(adjustmentRecommendations.map(\.id))
        dismissedRecommendationIds = dismissedRecommendationIds.intersection(currentIds)

        Task {
            guard let snapshot = try? await fitnessRepository.getLatestSnapshot() else { return }
            adjustmentRecommendations = PlanAdjustmentCalculator.analyze(
                plan: plan, fitnessSnapshot: snapshot
            )
            let updatedIds = Set(adjustmentRecommendations.map(\.id))
            dismissedRecommendationIds = dismissedRecommendationIds.intersection(updatedIds)
        }
    }

    func dismissRecommendation(_ recommendation: PlanAdjustmentRecommendation) {
        dismissedRecommendationIds.insert(recommendation.id)
    }

    func applyRecommendation(_ recommendation: PlanAdjustmentRecommendation) async {
        guard var currentPlan = plan else { return }
        isApplyingAdjustment = true

        do {
            switch recommendation.type {
            case .rescheduleKeySession:
                try await applyReschedule(recommendation, plan: &currentPlan)
            case .reduceVolumeAfterLowAdherence:
                let factor = 1.0 - AppConfiguration.Training.lowAdherenceVolumeReductionPercent / 100.0
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
            case .convertToRecoveryWeek:
                let factor = 1.0 - AppConfiguration.Training.recoveryWeekVolumeReductionPercent / 100.0
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
                if let cwi = currentPlan.currentWeekIndex {
                    currentPlan.weeks[cwi].isRecoveryWeek = true
                    try await planRepository.updatePlan(currentPlan)
                }
            case .bulkMarkMissedAsSkipped:
                try await applyBulkSkip(recommendation, plan: &currentPlan)
            case .reduceFatigueLoad:
                let isSevere = recommendation.severity == .urgent
                let factor = isSevere ? 0.75 : 0.85
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
            case .swapToRecovery:
                try await applySwapToRecovery(recommendation, plan: &currentPlan)
            }

            plan = currentPlan
            checkForAdjustments()
            await updateWidgets()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to apply adjustment: \(error)")
        }

        isApplyingAdjustment = false
    }

    private func applyReschedule(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        guard rec.affectedSessionIds.count == 2 else { return }
        let missedId = rec.affectedSessionIds[0]
        let restSlotId = rec.affectedSessionIds[1]

        guard let (mwi, msi) = findSession(id: missedId, in: plan),
              let (rwi, rsi) = findSession(id: restSlotId, in: plan) else { return }

        let newDate = plan.weeks[rwi].sessions[rsi].date
        plan.weeks[mwi].sessions[msi].date = newDate

        plan.weeks[mwi].sessions.sort { $0.date < $1.date }
        if mwi != rwi {
            plan.weeks[rwi].sessions.sort { $0.date < $1.date }
        }

        // Find the updated index after sort
        if let updatedIdx = plan.weeks[mwi].sessions.firstIndex(where: { $0.id == missedId }) {
            try await planRepository.updateSession(plan.weeks[mwi].sessions[updatedIdx])
        }
    }

    private func applyVolumeReduction(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan,
        factor: Double
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)

        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                let session = plan.weeks[wi].sessions[si]
                guard affectedIds.contains(session.id) else { continue }

                plan.weeks[wi].sessions[si].plannedDistanceKm *= factor
                plan.weeks[wi].sessions[si].plannedElevationGainM *= factor
                plan.weeks[wi].sessions[si].plannedDuration *= factor
                try await planRepository.updateSession(plan.weeks[wi].sessions[si])
            }
        }
    }

    private func applyBulkSkip(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)

        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                guard affectedIds.contains(plan.weeks[wi].sessions[si].id) else { continue }
                plan.weeks[wi].sessions[si].isSkipped = true
                try await planRepository.updateSession(plan.weeks[wi].sessions[si])
            }
        }
    }

    private func applySwapToRecovery(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        guard let sessionId = rec.affectedSessionIds.first,
              let (wi, si) = findSession(id: sessionId, in: plan) else { return }

        plan.weeks[wi].sessions[si].type = .recovery
        plan.weeks[wi].sessions[si].intensity = .easy
        plan.weeks[wi].sessions[si].plannedDistanceKm *= 0.5
        plan.weeks[wi].sessions[si].plannedElevationGainM = 0
        plan.weeks[wi].sessions[si].plannedDuration *= 0.5
        plan.weeks[wi].sessions[si].description = "Recovery run (auto-adjusted due to high fatigue)"
        try await planRepository.updateSession(plan.weeks[wi].sessions[si])
    }

    private func findSession(id: UUID, in plan: TrainingPlan) -> (weekIndex: Int, sessionIndex: Int)? {
        for (wi, week) in plan.weeks.enumerated() {
            for (si, session) in week.sessions.enumerated() {
                if session.id == id { return (wi, si) }
            }
        }
        return nil
    }

    // MARK: - Progress Preservation

    private func updateWidgets() async {
        await widgetDataWriter.writeNextSession()
        await widgetDataWriter.writeWeeklyProgress()
        widgetDataWriter.reloadWidgets()
    }

}
