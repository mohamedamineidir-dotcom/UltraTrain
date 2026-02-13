import Foundation

protocol TrainingPlanRepository: Sendable {
    func getActivePlan() async throws -> TrainingPlan?
    func getPlan(id: UUID) async throws -> TrainingPlan?
    func savePlan(_ plan: TrainingPlan) async throws
    func updatePlan(_ plan: TrainingPlan) async throws
    func updateSession(_ session: TrainingSession) async throws
}
