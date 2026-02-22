import Foundation
import os

@Observable
@MainActor
final class GoalHistoryViewModel {
    private let goalRepository: any GoalRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

    var weeklyHistory: [(goal: TrainingGoal, progress: GoalProgress)] = []
    var monthlyHistory: [(goal: TrainingGoal, progress: GoalProgress)] = []
    var isLoading = false
    var error: String?

    init(
        goalRepository: any GoalRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        self.goalRepository = goalRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
    }

    func load() async {
        isLoading = true
        do {
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)

            let weeklyGoals = try await goalRepository.getGoalHistory(period: .weekly, limit: 12)
            weeklyHistory = weeklyGoals.map { goal in
                let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)
                return (goal: goal, progress: progress)
            }

            let monthlyGoals = try await goalRepository.getGoalHistory(period: .monthly, limit: 6)
            monthlyHistory = monthlyGoals.map { goal in
                let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)
                return (goal: goal, progress: progress)
            }
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load goal history: \(error)")
        }
        isLoading = false
    }
}
