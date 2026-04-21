import Foundation

protocol NutritionRepository: Sendable {
    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan?
    func saveNutritionPlan(_ plan: NutritionPlan) async throws
    func updateNutritionPlan(_ plan: NutritionPlan) async throws
    func getProducts() async throws -> [NutritionProduct]
    func saveProduct(_ product: NutritionProduct) async throws
    func getNutritionPreferences() async throws -> NutritionPreferences
    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws
    /// Persists post-long-run nutrition feedback. Replaces any existing
    /// feedback for the same sessionId (an athlete re-logging the same run).
    func saveNutritionFeedback(_ feedback: NutritionSessionFeedback) async throws
    /// Returns all feedback entries, newest first. Used by the refinement
    /// use case and the Nutrition tab's training-log section.
    func getNutritionFeedbacks() async throws -> [NutritionSessionFeedback]
}
