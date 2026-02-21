import Foundation
@testable import UltraTrain

final class MockGoalRepository: GoalRepository, @unchecked Sendable {
    var goals: [TrainingGoal] = []
    var savedGoal: TrainingGoal?
    var deletedId: UUID?
    var shouldThrow = false

    func getActiveGoal(period: GoalPeriod) async throws -> TrainingGoal? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        let now = Date.now
        return goals.first { $0.period == period && $0.startDate <= now && $0.endDate >= now }
    }

    func getGoalHistory(period: GoalPeriod, limit: Int) async throws -> [TrainingGoal] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return Array(goals.filter { $0.period == period }.prefix(limit))
    }

    func saveGoal(_ goal: TrainingGoal) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedGoal = goal
        goals.append(goal)
    }

    func deleteGoal(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deletedId = id
        goals.removeAll { $0.id == id }
    }
}
