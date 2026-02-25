import Foundation

final class RemoteFriendDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFriends() async throws -> [FriendConnectionResponseDTO] {
        try await apiClient.send(FriendEndpoints.FetchAll())
    }

    func fetchPending() async throws -> [FriendConnectionResponseDTO] {
        try await apiClient.send(FriendEndpoints.FetchPending())
    }

    func sendRequest(_ dto: FriendRequestRequestDTO) async throws -> FriendConnectionResponseDTO {
        try await apiClient.send(FriendEndpoints.SendRequest(body: dto))
    }

    func acceptRequest(connectionId: String) async throws -> FriendConnectionResponseDTO {
        try await apiClient.send(FriendEndpoints.Accept(connectionId: connectionId))
    }

    func declineRequest(connectionId: String) async throws -> FriendConnectionResponseDTO {
        try await apiClient.send(FriendEndpoints.Decline(connectionId: connectionId))
    }

    func removeFriend(connectionId: String) async throws {
        try await apiClient.sendVoid(FriendEndpoints.Remove(connectionId: connectionId))
    }
}
