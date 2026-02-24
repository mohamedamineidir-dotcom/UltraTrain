import Foundation
import os

actor FoodDatabaseService: FoodDatabaseServiceProtocol {
    private let dataSource: OpenFoodFactsDataSource
    private let logger = Logger(subsystem: "com.ultratrain", category: "FoodDatabase")

    init(dataSource: OpenFoodFactsDataSource = OpenFoodFactsDataSource()) {
        self.dataSource = dataSource
    }

    func searchByBarcode(_ barcode: String) async throws -> FoodSearchResult? {
        let dto = try await dataSource.fetchProduct(barcode: barcode)
        guard let dto else { return nil }
        return FoodSearchResultMapper.map(dto)
    }

    func searchByName(_ query: String) async throws -> [FoodSearchResult] {
        let dtos = try await dataSource.searchProducts(query: query)
        return dtos.compactMap { FoodSearchResultMapper.map($0) }
    }
}
