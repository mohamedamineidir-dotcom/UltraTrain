import Foundation

protocol TrainingPlanRepository: Sendable {
    /// The single active (non-archived) plan.
    func getActivePlan() async throws -> TrainingPlan?
    /// All stored plans, active + archived. Used to find a preserved custom
    /// plan to restore, or a scenario plan to surface.
    func getAllPlans() async throws -> [TrainingPlan]
    func getPlan(id: UUID) async throws -> TrainingPlan?
    /// Saves a plan as the new active one. The previously-active plan of the
    /// OTHER kind (custom vs scenario) is archived rather than deleted, so it
    /// survives for later restoration; a prior plan of the SAME kind is
    /// replaced.
    func savePlan(_ plan: TrainingPlan) async throws
    /// Makes the given plan the active one and archives all others.
    func setActivePlan(id: UUID) async throws
    func updatePlan(_ plan: TrainingPlan) async throws
    func updateSession(_ session: TrainingSession) async throws
}
