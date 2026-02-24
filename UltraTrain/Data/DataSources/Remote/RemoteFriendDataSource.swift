import Foundation

final class RemoteFriendDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFriends() async throws -> [FriendConnectionResponseDTO] {
        try await apiClient.request(
            path: FriendEndpoints.friendsPath,
            method: .get,
            requiresAuth: true
        )
    }

    func fetchPending() async throws -> [FriendConnectionResponseDTO] {
        try await apiClient.request(
            path: FriendEndpoints.pendingPath,
            method: .get,
            requiresAuth: true
        )
    }

    func sendRequest(_ dto: FriendRequestRequestDTO) async throws -> FriendConnectionResponseDTO {
        try await apiClient.request(
            path: FriendEndpoints.requestPath,
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }

    func acceptRequest(connectionId: String) async throws -> FriendConnectionResponseDTO {
        try await apiClient.request(
            path: FriendEndpoints.acceptPath(id: connectionId),
            method: .put,
            requiresAuth: true
        )
    }

    func declineRequest(connectionId: String) async throws -> FriendConnectionResponseDTO {
        try await apiClient.request(
            path: FriendEndpoints.declinePath(id: connectionId),
            method: .put,
            requiresAuth: true
        )
    }

    func removeFriend(connectionId: String) async throws {
        try await apiClient.requestVoid(
            path: FriendEndpoints.friendPath(id: connectionId),
            method: .delete,
            requiresAuth: true
        )
    }
}
