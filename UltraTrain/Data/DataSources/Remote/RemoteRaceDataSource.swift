import Foundation

final class RemoteRaceDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func upsertRace(_ dto: RaceUploadRequestDTO) async throws -> RaceResponseDTO {
        try await apiClient.send(RaceEndpoints.Upsert(body: dto))
    }

    func fetchRaces(cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<RaceResponseDTO> {
        try await apiClient.send(RaceEndpoints.FetchAll(cursor: cursor, limit: limit))
    }

    func deleteRace(id: String) async throws {
        try await apiClient.sendVoid(RaceEndpoints.Delete(id: id))
    }
}
