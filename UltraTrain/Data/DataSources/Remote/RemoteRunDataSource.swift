import Foundation

final class RemoteRunDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func uploadRun(_ dto: RunUploadRequestDTO) async throws -> RunResponseDTO {
        try await apiClient.request(
            path: RunEndpoints.runsPath,
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }

    func deleteRun(id: UUID) async throws {
        try await apiClient.requestVoid(
            path: RunEndpoints.runPath(id: id.uuidString),
            method: .delete,
            requiresAuth: true
        )
    }

    func fetchRuns(since: Date? = nil) async throws -> [RunResponseDTO] {
        var queryItems: [URLQueryItem]?
        if let since {
            let formatter = ISO8601DateFormatter()
            queryItems = [URLQueryItem(name: "since", value: formatter.string(from: since))]
        }
        return try await apiClient.request(
            path: RunEndpoints.runsPath,
            method: .get,
            queryItems: queryItems,
            requiresAuth: true
        )
    }
}
