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

    func updateRun(_ dto: RunUploadRequestDTO, id: UUID) async throws -> RunResponseDTO {
        try await apiClient.request(
            path: RunEndpoints.runPath(id: id.uuidString),
            method: .put,
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

    func fetchRuns(since: Date? = nil, cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponseDTO<RunResponseDTO> {
        let formatter = ISO8601DateFormatter()
        var queryItems: [URLQueryItem] = []
        if let since {
            queryItems.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
        }
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        return try await apiClient.request(
            path: RunEndpoints.runsPath,
            method: .get,
            queryItems: queryItems.isEmpty ? nil : queryItems,
            requiresAuth: true
        )
    }
}
