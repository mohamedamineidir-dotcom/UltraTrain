import Foundation

enum FoodSearchResultMapper {
    static func map(_ dto: OpenFoodFactsProductDTO) -> FoodSearchResult? {
        guard let name = dto.productName, !name.isEmpty else { return nil }
        return FoodSearchResult(
            id: dto.code ?? UUID().uuidString,
            name: name,
            brand: dto.brands,
            caloriesPer100g: dto.nutriments?.energyKcal100g.flatMap { Int($0) },
            carbsPer100g: dto.nutriments?.carbohydrates100g,
            proteinPer100g: dto.nutriments?.proteins100g,
            fatPer100g: dto.nutriments?.fat100g,
            sodiumMgPer100g: dto.nutriments?.sodium100g.map { $0 * 1000 },
            servingSizeGrams: dto.servingQuantity,
            imageURL: dto.imageUrl.flatMap { URL(string: $0) }
        )
    }
}
