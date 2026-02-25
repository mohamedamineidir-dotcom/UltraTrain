import Foundation

final class RemoteGroupChallengeDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func createChallenge(_ dto: CreateChallengeRequestDTO) async throws -> GroupChallengeResponseDTO {
        try await apiClient.send(ChallengeEndpoints.Create(body: dto))
    }

    func fetchChallenges(status: String? = nil) async throws -> [GroupChallengeResponseDTO] {
        try await apiClient.send(ChallengeEndpoints.FetchAll(status: status))
    }

    func fetchChallenge(id: String) async throws -> GroupChallengeResponseDTO {
        try await apiClient.send(ChallengeEndpoints.FetchOne(id: id))
    }

    func joinChallenge(id: String) async throws -> GroupChallengeResponseDTO {
        try await apiClient.send(ChallengeEndpoints.Join(id: id))
    }

    func leaveChallenge(id: String) async throws {
        try await apiClient.sendVoid(ChallengeEndpoints.Leave(id: id))
    }

    func updateProgress(challengeId: String, dto: UpdateProgressRequestDTO) async throws -> ChallengeParticipantResponseDTO {
        try await apiClient.send(ChallengeEndpoints.UpdateProgress(challengeId: challengeId, body: dto))
    }
}
