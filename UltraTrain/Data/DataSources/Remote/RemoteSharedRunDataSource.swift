import Foundation

final class RemoteSharedRunDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func shareRun(_ dto: ShareRunRequestDTO) async throws -> SharedRunResponseDTO {
        try await apiClient.request(
            path: SharedRunEndpoints.sharedRunsPath,
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }

    func fetchSharedRuns(limit: Int = 20) async throws -> [SharedRunResponseDTO] {
        try await apiClient.request(
            path: SharedRunEndpoints.sharedRunsPath,
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))],
            requiresAuth: true
        )
    }

    func fetchMySharedRuns() async throws -> [SharedRunResponseDTO] {
        try await apiClient.request(
            path: SharedRunEndpoints.mySharedRunsPath,
            method: .get,
            requiresAuth: true
        )
    }

    func revokeShare(id: String) async throws {
        try await apiClient.requestVoid(
            path: SharedRunEndpoints.sharedRunPath(id: id),
            method: .delete,
            requiresAuth: true
        )
    }
}
