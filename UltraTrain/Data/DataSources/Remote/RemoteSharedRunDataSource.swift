import Foundation

final class RemoteSharedRunDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func shareRun(_ dto: ShareRunRequestDTO) async throws -> SharedRunResponseDTO {
        try await apiClient.send(SharedRunEndpoints.Share(body: dto))
    }

    func fetchSharedRuns(limit: Int = 20) async throws -> [SharedRunResponseDTO] {
        try await apiClient.send(SharedRunEndpoints.FetchAll(limit: limit))
    }

    func fetchMySharedRuns() async throws -> [SharedRunResponseDTO] {
        try await apiClient.send(SharedRunEndpoints.FetchMine())
    }

    func revokeShare(id: String) async throws {
        try await apiClient.sendVoid(SharedRunEndpoints.Revoke(id: id))
    }
}
