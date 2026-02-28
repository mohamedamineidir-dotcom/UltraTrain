import Foundation

final class RemoteFinishEstimateDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func upsertEstimate(_ dto: FinishEstimateUploadRequestDTO) async throws -> FinishEstimateResponseDTO {
        try await apiClient.send(FinishEstimateEndpoints.Upsert(body: dto))
    }

    func fetchEstimates(cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<FinishEstimateResponseDTO> {
        try await apiClient.send(FinishEstimateEndpoints.FetchAll(cursor: cursor, limit: limit))
    }
}
