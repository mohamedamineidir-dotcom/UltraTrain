import Foundation

final class RemoteGroupChallengeDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func createChallenge(_ dto: CreateChallengeRequestDTO) async throws -> GroupChallengeResponseDTO {
        try await apiClient.request(
            path: ChallengeEndpoints.challengesPath,
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }

    func fetchChallenges(status: String? = nil) async throws -> [GroupChallengeResponseDTO] {
        var queryItems: [URLQueryItem] = []
        if let status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await apiClient.request(
            path: ChallengeEndpoints.challengesPath,
            method: .get,
            queryItems: queryItems.isEmpty ? nil : queryItems,
            requiresAuth: true
        )
    }

    func fetchChallenge(id: String) async throws -> GroupChallengeResponseDTO {
        try await apiClient.request(
            path: ChallengeEndpoints.challengePath(id: id),
            method: .get,
            requiresAuth: true
        )
    }

    func joinChallenge(id: String) async throws -> GroupChallengeResponseDTO {
        try await apiClient.request(
            path: ChallengeEndpoints.joinPath(id: id),
            method: .post,
            requiresAuth: true
        )
    }

    func leaveChallenge(id: String) async throws {
        try await apiClient.requestVoid(
            path: ChallengeEndpoints.leavePath(id: id),
            method: .post,
            requiresAuth: true
        )
    }

    func updateProgress(challengeId: String, dto: UpdateProgressRequestDTO) async throws -> ChallengeParticipantResponseDTO {
        try await apiClient.request(
            path: ChallengeEndpoints.progressPath(id: challengeId),
            method: .put,
            body: dto,
            requiresAuth: true
        )
    }
}
