import Foundation

final class RemoteFitnessDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func upsertSnapshot(_ dto: FitnessSnapshotUploadRequestDTO) async throws -> FitnessSnapshotResponseDTO {
        try await apiClient.send(FitnessEndpoints.Upsert(body: dto))
    }

    func fetchSnapshots(cursor: String? = nil, limit: Int = 100) async throws -> PaginatedResponseDTO<FitnessSnapshotResponseDTO> {
        try await apiClient.send(FitnessEndpoints.FetchAll(cursor: cursor, limit: limit))
    }
}
