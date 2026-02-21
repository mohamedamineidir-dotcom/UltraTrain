import Foundation
@testable import UltraTrain

final class MockFriendRepository: FriendRepository, @unchecked Sendable {
    var friends: [FriendConnection] = []
    var pendingRequests: [FriendConnection] = []
    var sentRequest: FriendConnection?
    var acceptedId: UUID?
    var declinedId: UUID?
    var removedId: UUID?

    func fetchFriends() async throws -> [FriendConnection] { friends }
    func fetchPendingRequests() async throws -> [FriendConnection] { pendingRequests }

    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        let conn = FriendConnection(
            id: UUID(),
            friendProfileId: toProfileId,
            friendDisplayName: displayName,
            friendPhotoData: nil,
            status: .pending,
            createdDate: Date.now,
            acceptedDate: nil
        )
        sentRequest = conn
        return conn
    }

    func acceptFriendRequest(_ connectionId: UUID) async throws { acceptedId = connectionId }
    func declineFriendRequest(_ connectionId: UUID) async throws { declinedId = connectionId }
    func removeFriend(_ connectionId: UUID) async throws { removedId = connectionId }
}
