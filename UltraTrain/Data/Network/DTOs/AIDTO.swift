import Foundation

struct FoodPhotoRequestDTO: Encodable, Sendable {
    let image: String
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
