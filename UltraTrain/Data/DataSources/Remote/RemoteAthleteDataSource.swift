import Foundation

final class RemoteAthleteDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchAthlete() async throws -> AthleteDTO {
        try await apiClient.request(
            path: AthleteEndpoints.athletePath,
            method: .get,
            requiresAuth: true
        )
    }

    func updateAthlete(_ dto: AthleteDTO) async throws -> AthleteDTO {
        try await apiClient.request(
            path: AthleteEndpoints.athletePath,
            method: .put,
            body: dto,
            requiresAuth: true
        )
    }
}
