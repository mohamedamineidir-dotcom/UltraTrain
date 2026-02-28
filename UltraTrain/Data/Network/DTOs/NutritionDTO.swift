import Foundation

struct NutritionUploadRequestDTO: Encodable, Sendable {
    let nutritionPlanId: String
    let raceId: String
    let caloriesPerHour: Int
    let nutritionJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?
}

struct NutritionResponseDTO: Decodable, Sendable {
    let id: String
    let nutritionPlanId: String
    let raceId: String
    let caloriesPerHour: Int
    let nutritionJson: String
    let createdAt: String?
    let updatedAt: String?
}
