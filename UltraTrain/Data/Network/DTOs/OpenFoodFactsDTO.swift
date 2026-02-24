import Foundation

struct OpenFoodFactsProductResponse: Decodable, Sendable {
    let status: Int
    let product: OpenFoodFactsProductDTO?
}

struct OpenFoodFactsProductDTO: Decodable, Sendable {
    let code: String?
    let productName: String?
    let brands: String?
    let nutriments: OpenFoodFactsNutrimentsDTO?
    let servingQuantity: Double?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case nutriments
        case servingQuantity = "serving_quantity"
        case imageUrl = "image_url"
    }
}

struct OpenFoodFactsNutrimentsDTO: Decodable, Sendable {
    let energyKcal100g: Double?
    let carbohydrates100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let sodium100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case sodium100g = "sodium_100g"
    }
}

struct OpenFoodFactsSearchResponse: Decodable, Sendable {
    let count: Int
    let products: [OpenFoodFactsProductDTO]
}
