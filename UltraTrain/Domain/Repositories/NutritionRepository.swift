import Foundation

protocol NutritionRepository: Sendable {
    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan?
    func saveNutritionPlan(_ plan: NutritionPlan) async throws
    func updateNutritionPlan(_ plan: NutritionPlan) async throws
    func getProducts() async throws -> [NutritionProduct]
    func saveProduct(_ product: NutritionProduct) async throws
}
