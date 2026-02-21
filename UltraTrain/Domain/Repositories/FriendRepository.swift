import Foundation

protocol FriendRepository: Sendable {
    func fetchFriends() async throws -> [FriendConnection]
    func fetchPendingRequests() async throws -> [FriendConnection]
    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection
    func acceptFriendRequest(_ connectionId: UUID) async throws
    func declineFriendRequest(_ connectionId: UUID) async throws
    func removeFriend(_ connectionId: UUID) async throws
}
