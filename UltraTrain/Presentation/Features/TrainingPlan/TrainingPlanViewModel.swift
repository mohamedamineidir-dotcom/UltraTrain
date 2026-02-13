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

    // MARK: - State

    var plan: TrainingPlan?
    var isLoading = false
    var isGenerating = false
    var error: String?

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase
    ) {
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planGenerator = planGenerator
    }

    // MARK: - Load

    func loadPlan() async {
        isLoading = true
        error = nil

        do {
            plan = try await planRepository.getActivePlan()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load plan: \(error)")
        }

        isLoading = false
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

            let newPlan = try await planGenerator.execute(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces
            )

            try await planRepository.savePlan(newPlan)
            plan = newPlan
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

    // MARK: - Computed

    var currentWeek: TrainingWeek? {
        plan?.weeks.first { $0.containsToday }
    }

    var nextSession: TrainingSession? {
        guard let week = currentWeek else { return nil }
        let now = Date.now.startOfDay
        return week.sessions
            .filter { !$0.isCompleted && $0.date >= now && $0.type != .rest }
            .sorted { $0.date < $1.date }
            .first
    }

    var weeklyProgress: (completed: Int, total: Int) {
        guard let week = currentWeek else { return (0, 0) }
        let activeSessions = week.sessions.filter { $0.type != .rest }
        let completed = activeSessions.filter(\.isCompleted).count
        return (completed, activeSessions.count)
    }
}
