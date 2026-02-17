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

    // MARK: - State

    var plan: TrainingPlan?
    var races: [Race] = []
    var athlete: Athlete?
    var nutritionPreferences: NutritionPreferences = .default
    var isLoading = false
    var isGenerating = false
    var error: String?
    var showRegenerateConfirmation = false

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionAdvisor: any SessionNutritionAdvisor
    ) {
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionAdvisor = nutritionAdvisor
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
            let oldProgress = snapshotProgress()

            var newPlan = try await planGenerator.execute(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces
            )

            // Restore progress from old plan to matching sessions
            restoreProgress(oldProgress, into: &newPlan)

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
        let currentIntermediateIds = races
            .filter { $0.priority != .aRace && $0.date < target.date }
            .map(\.id)
            .sorted { $0.uuidString < $1.uuidString }
        let planIntermediateIds = plan.intermediateRaceIds
            .sorted { $0.uuidString < $1.uuidString }
        return currentIntermediateIds != planIntermediateIds
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

    // MARK: - Progress Preservation

    private struct SessionProgress {
        let weekNumber: Int
        let type: SessionType
        let dayOfWeek: Int
        let isCompleted: Bool
        let isSkipped: Bool
        let linkedRunId: UUID?
    }

    private func snapshotProgress() -> [SessionProgress] {
        guard let plan else { return [] }
        let calendar = Calendar.current
        return plan.weeks.flatMap { week in
            week.sessions
                .filter { $0.isCompleted || $0.isSkipped || $0.linkedRunId != nil }
                .map { session in
                    SessionProgress(
                        weekNumber: week.weekNumber,
                        type: session.type,
                        dayOfWeek: calendar.component(.weekday, from: session.date),
                        isCompleted: session.isCompleted,
                        isSkipped: session.isSkipped,
                        linkedRunId: session.linkedRunId
                    )
                }
        }
    }

    private func restoreProgress(_ progress: [SessionProgress], into plan: inout TrainingPlan) {
        let calendar = Calendar.current
        for weekIndex in plan.weeks.indices {
            let weekNumber = plan.weeks[weekIndex].weekNumber
            for sessionIndex in plan.weeks[weekIndex].sessions.indices {
                let session = plan.weeks[weekIndex].sessions[sessionIndex]
                let dayOfWeek = calendar.component(.weekday, from: session.date)
                if let match = progress.first(where: {
                    $0.weekNumber == weekNumber && $0.type == session.type && $0.dayOfWeek == dayOfWeek
                }) {
                    plan.weeks[weekIndex].sessions[sessionIndex].isCompleted = match.isCompleted
                    plan.weeks[weekIndex].sessions[sessionIndex].isSkipped = match.isSkipped
                    plan.weeks[weekIndex].sessions[sessionIndex].linkedRunId = match.linkedRunId
                }
            }
        }
    }
}
