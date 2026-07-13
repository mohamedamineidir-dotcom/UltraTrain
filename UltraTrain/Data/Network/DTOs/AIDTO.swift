import Foundation

struct FoodPhotoRequestDTO: Encodable, Sendable {
    let image: String
    /// BCP-47 language code (e.g. "fr", "en") the athlete's device is set
    /// to, so the backend can ask the vision model to name foods in that
    /// language instead of always English.
    let languageCode: String
}

struct FoodPhotoResponseDTO: Decodable, Sendable {
    let items: [AnalyzedFoodItemDTO]
}

struct AnalyzedFoodItemDTO: Decodable, Sendable {
    let name: String
    let portionGrams: Double
    let calories: Int
    let carbsGrams: Double
    let proteinGrams: Double
    let fatGrams: Double
}
