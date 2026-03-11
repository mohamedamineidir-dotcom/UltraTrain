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
        let localResults = CommonFoodDatabase.search(query)

        let apiResults: [FoodSearchResult]
        do {
            let dtos = try await dataSource.searchProducts(query: query)
            apiResults = dtos.compactMap { FoodSearchResultMapper.map($0) }
        } catch {
            logger.debug("API food search failed: \(error)")
            apiResults = []
        }

        // Merge: local first, then API (dedup by lowercase name)
        let localNames = Set(localResults.map { $0.name.lowercased() })
        let uniqueApi = apiResults.filter { !localNames.contains($0.name.lowercased()) }
        return localResults + uniqueApi
    }

    /// Local-only search for instant results (no network call).
    func searchLocal(_ query: String) -> [FoodSearchResult] {
        CommonFoodDatabase.search(query)
    }
}
