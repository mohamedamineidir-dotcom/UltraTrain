import Foundation

final class RemoteRaceDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func upsertRace(_ dto: RaceUploadRequestDTO) async throws -> RaceResponseDTO {
        try await apiClient.request(
            path: RaceEndpoints.racesPath,
            method: .put,
            body: dto,
            requiresAuth: true
        )
    }

    func fetchRaces(cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<RaceResponseDTO> {
        var queryItems: [URLQueryItem] = []
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        return try await apiClient.request(
            path: RaceEndpoints.racesPath,
            method: .get,
            queryItems: queryItems.isEmpty ? nil : queryItems,
            requiresAuth: true
        )
    }

    func deleteRace(id: String) async throws {
        try await apiClient.requestVoid(
            path: RaceEndpoints.racePath(id: id),
            method: .delete,
            requiresAuth: true
        )
    }
}
