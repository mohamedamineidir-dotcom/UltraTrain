import Foundation

final class RemoteRunDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func uploadRun(_ dto: RunUploadRequestDTO) async throws -> RunResponseDTO {
        try await apiClient.send(RunEndpoints.Upload(body: dto))
    }

    func updateRun(_ dto: RunUploadRequestDTO, id: UUID) async throws -> RunResponseDTO {
        try await apiClient.send(RunEndpoints.Update(id: id, body: dto))
    }

    func deleteRun(id: UUID) async throws {
        try await apiClient.sendVoid(RunEndpoints.Delete(id: id))
    }

    func fetchRuns(since: Date? = nil, cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<RunResponseDTO> {
        try await apiClient.send(RunEndpoints.FetchAll(since: since, cursor: cursor, limit: limit))
    }
}
