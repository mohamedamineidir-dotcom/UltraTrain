import Foundation

final class RemoteNutritionDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func upsertNutrition(_ dto: NutritionUploadRequestDTO) async throws -> NutritionResponseDTO {
        try await apiClient.send(NutritionEndpoints.Upsert(body: dto))
    }

    func fetchNutrition(cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<NutritionResponseDTO> {
        try await apiClient.send(NutritionEndpoints.FetchAll(cursor: cursor, limit: limit))
    }
}
