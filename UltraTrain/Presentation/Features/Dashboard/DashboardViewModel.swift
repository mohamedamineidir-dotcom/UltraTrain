import Foundation
import os

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Dependencies

    private let planRepository: any TrainingPlanRepository

    // MARK: - State

    var plan: TrainingPlan?
    var isLoading = false

    // MARK: - Init

    init(planRepository: any TrainingPlanRepository) {
        self.planRepository = planRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        do {
            plan = try await planRepository.getActivePlan()
        } catch {
            Logger.training.error("Dashboard failed to load plan: \(error)")
        }
        isLoading = false
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
        let active = week.sessions.filter { $0.type != .rest }
        let done = active.filter(\.isCompleted).count
        return (done, active.count)
    }

    var weeklyDistanceKm: Double {
        guard let week = currentWeek else { return 0 }
        return week.sessions.filter(\.isCompleted).reduce(0) { $0 + $1.plannedDistanceKm }
    }

    var weeklyElevationM: Double {
        guard let week = currentWeek else { return 0 }
        return week.sessions.filter(\.isCompleted).reduce(0) { $0 + $1.plannedElevationGainM }
    }

    var weeksUntilRace: Int? {
        guard let plan else { return nil }
        let lastWeek = plan.weeks.last
        guard let raceEnd = lastWeek?.endDate else { return nil }
        return Date.now.weeksBetween(raceEnd)
    }
}
