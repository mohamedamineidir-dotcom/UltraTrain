import Foundation

enum NutritionRemoteMapper {
    static func toUploadDTO(_ plan: NutritionPlan) -> NutritionUploadRequestDTO? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(plan),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return NutritionUploadRequestDTO(
            nutritionPlanId: plan.id.uuidString,
            raceId: plan.raceId.uuidString,
            caloriesPerHour: plan.caloriesPerHour,
            nutritionJson: jsonString,
            idempotencyKey: plan.id.uuidString,
            clientUpdatedAt: nil
        )
    }

    static func toDomain(from response: NutritionResponseDTO) -> NutritionPlan? {
        guard let jsonData = response.nutritionJson.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NutritionPlan.self, from: jsonData)
    }
}
