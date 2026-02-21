import Foundation

protocol GoalRepository: Sendable {
    func getActiveGoal(period: GoalPeriod) async throws -> TrainingGoal?
    func getGoalHistory(period: GoalPeriod, limit: Int) async throws -> [TrainingGoal]
    func saveGoal(_ goal: TrainingGoal) async throws
    func deleteGoal(id: UUID) async throws
}
