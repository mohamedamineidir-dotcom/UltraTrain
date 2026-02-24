import Foundation
import os

actor OpenFoodFactsDataSource {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.ultratrain", category: "OpenFoodFacts")

    private static let baseURL = URL(string: "https://world.openfoodfacts.org")!

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO? {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed.allSatisfy(\.isNumber),
              trimmed.count >= 8, trimmed.count <= 14 else {
            logger.debug("Invalid barcode format: \(barcode, privacy: .public)")
            return nil
        }

        let url = Self.baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v2")
            .appendingPathComponent("product")
            .appendingPathComponent("\(trimmed).json")
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("UltraTrain iOS", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(OpenFoodFactsProductResponse.self, from: data)

        guard response.status == 1 else { return nil }
        return response.product
    }

    func searchProducts(query: String) async throws -> [OpenFoodFactsProductDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent("cgi/search.pl"),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20")
        ]

        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("UltraTrain iOS", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(OpenFoodFactsSearchResponse.self, from: data)
        return response.products
    }
}
