import Foundation
@testable import UltraTrain

final class MockTrainingPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    var activePlan: TrainingPlan?
    var plans: [UUID: TrainingPlan] = [:]
    var updatedSessions: [TrainingSession] = []
    var shouldThrow = false

    func getActivePlan() async throws -> TrainingPlan? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return activePlan
    }

    func getPlan(id: UUID) async throws -> TrainingPlan? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return plans[id]
    }

    func savePlan(_ plan: TrainingPlan) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        activePlan = plan
        plans[plan.id] = plan
    }

    func updatePlan(_ plan: TrainingPlan) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        activePlan = plan
        plans[plan.id] = plan
    }

    func updateSession(_ session: TrainingSession) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updatedSessions.append(session)
    }
}
