import Foundation

protocol FoodDatabaseServiceProtocol: Sendable {
    func searchByBarcode(_ barcode: String) async throws -> FoodSearchResult?
    func searchByName(_ query: String) async throws -> [FoodSearchResult]
}
