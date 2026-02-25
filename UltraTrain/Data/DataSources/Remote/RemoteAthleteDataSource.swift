import Foundation

final class RemoteAthleteDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchAthlete() async throws -> AthleteDTO {
        try await apiClient.send(AthleteEndpoints.Fetch())
    }

    func updateAthlete(_ dto: AthleteDTO) async throws -> AthleteDTO {
        try await apiClient.send(AthleteEndpoints.Update(body: dto))
    }
}
