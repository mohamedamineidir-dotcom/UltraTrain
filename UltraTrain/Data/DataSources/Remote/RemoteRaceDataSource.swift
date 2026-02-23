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

    func fetchRaces() async throws -> [RaceResponseDTO] {
        try await apiClient.request(
            path: RaceEndpoints.racesPath,
            method: .get,
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
