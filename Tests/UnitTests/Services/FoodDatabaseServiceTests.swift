import Foundation
import Testing
@testable import UltraTrain

@Suite("FoodDatabaseService Tests")
struct FoodDatabaseServiceTests {

    // MARK: - OpenFoodFactsDataSource Barcode Validation

    @Test("OpenFoodFactsDataSource rejects empty barcode")
    func rejectsEmptyBarcode() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let result = try await dataSource.fetchProduct(barcode: "")
        #expect(result == nil)
    }

    @Test("OpenFoodFactsDataSource rejects barcode with non-numeric characters")
    func rejectsNonNumericBarcode() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let result = try await dataSource.fetchProduct(barcode: "abc12345")
        #expect(result == nil)
    }

    @Test("OpenFoodFactsDataSource rejects barcode shorter than 8 digits")
    func rejectsTooShortBarcode() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let result = try await dataSource.fetchProduct(barcode: "1234567")
        #expect(result == nil)
    }

    @Test("OpenFoodFactsDataSource rejects barcode longer than 14 digits")
    func rejectsTooLongBarcode() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let result = try await dataSource.fetchProduct(barcode: "123456789012345")
        #expect(result == nil)
    }

    @Test("OpenFoodFactsDataSource trims whitespace from barcode")
    func trimsWhitespaceFromBarcode() async throws {
        // A barcode of spaces only should be rejected as empty after trim
        let dataSource = OpenFoodFactsDataSource()
        let result = try await dataSource.fetchProduct(barcode: "   ")
        #expect(result == nil)
    }

    // MARK: - OpenFoodFactsDataSource Search Validation

    @Test("OpenFoodFactsDataSource returns empty for blank search query")
    func emptySearchQueryReturnsEmpty() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let results = try await dataSource.searchProducts(query: "")
        #expect(results.isEmpty)
    }

    @Test("OpenFoodFactsDataSource returns empty for whitespace-only search query")
    func whitespaceSearchQueryReturnsEmpty() async throws {
        let dataSource = OpenFoodFactsDataSource()
        let results = try await dataSource.searchProducts(query: "   ")
        #expect(results.isEmpty)
    }

    // MARK: - FoodSearchResultMapper

    @Test("FoodSearchResultMapper maps complete DTO correctly")
    func mapperMapsCompleteDTO() {
        let nutriments = OpenFoodFactsNutrimentsDTO(
            energyKcal100g: 350,
            carbohydrates100g: 60.0,
            proteins100g: 10.0,
            fat100g: 8.0,
            sodium100g: 0.5
        )
        let dto = OpenFoodFactsProductDTO(
            code: "3017620422003",
            productName: "Nutella",
            brands: "Ferrero",
            nutriments: nutriments,
            servingQuantity: 15.0,
            imageUrl: "https://example.com/nutella.jpg"
        )

        let result = FoodSearchResultMapper.map(dto)

        #expect(result != nil)
        #expect(result?.name == "Nutella")
        #expect(result?.brand == "Ferrero")
        #expect(result?.caloriesPer100g == 350)
        #expect(result?.carbsPer100g == 60.0)
        #expect(result?.proteinPer100g == 10.0)
        #expect(result?.fatPer100g == 8.0)
        #expect(result?.servingSizeGrams == 15.0)
    }

    @Test("FoodSearchResultMapper returns nil for DTO with no product name")
    func mapperReturnsNilForMissingName() {
        let dto = OpenFoodFactsProductDTO(
            code: "123",
            productName: nil,
            brands: nil,
            nutriments: nil,
            servingQuantity: nil,
            imageUrl: nil
        )

        let result = FoodSearchResultMapper.map(dto)
        #expect(result == nil)
    }

    @Test("FoodSearchResultMapper returns nil for DTO with empty product name")
    func mapperReturnsNilForEmptyName() {
        let dto = OpenFoodFactsProductDTO(
            code: "123",
            productName: "",
            brands: nil,
            nutriments: nil,
            servingQuantity: nil,
            imageUrl: nil
        )

        let result = FoodSearchResultMapper.map(dto)
        #expect(result == nil)
    }

    // MARK: - FoodSearchResult Computed Properties

    @Test("caloriesPerServing calculates correctly")
    func caloriesPerServingCalculation() {
        let result = FoodSearchResult(
            id: "1",
            name: "Gel",
            caloriesPer100g: 250,
            servingSizeGrams: 40
        )

        // 250 * 40 / 100 = 100
        #expect(result.caloriesPerServing == 100)
    }

    @Test("caloriesPerServing falls back to per100g when no serving size")
    func caloriesPerServingFallback() {
        let result = FoodSearchResult(
            id: "1",
            name: "Gel",
            caloriesPer100g: 250,
            servingSizeGrams: nil
        )

        #expect(result.caloriesPerServing == 250)
    }
}
