import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("Local Friend Repository Tests")
@MainActor
struct LocalFriendRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self,
            GroupChallengeSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("Send friend request creates pending connection")
    func sendFriendRequestCreatesPending() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let connection = try await repo.sendFriendRequest(toProfileId: "friend-1", displayName: "Alice")

        #expect(connection.friendProfileId == "friend-1")
        #expect(connection.friendDisplayName == "Alice")
        #expect(connection.status == .pending)
        #expect(connection.acceptedDate == nil)

        let pending = try await repo.fetchPendingRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.friendProfileId == "friend-1")
    }

    @Test("Accept friend request updates status to accepted")
    func acceptFriendRequest() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let connection = try await repo.sendFriendRequest(toProfileId: "friend-2", displayName: "Bob")
        try await repo.acceptFriendRequest(connection.id)

        let friends = try await repo.fetchFriends()
        #expect(friends.count == 1)
        #expect(friends.first?.friendDisplayName == "Bob")
        #expect(friends.first?.status == .accepted)
        #expect(friends.first?.acceptedDate != nil)

        let pending = try await repo.fetchPendingRequests()
        #expect(pending.isEmpty)
    }

    @Test("Decline friend request updates status to declined")
    func declineFriendRequest() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let connection = try await repo.sendFriendRequest(toProfileId: "friend-3", displayName: "Charlie")
        try await repo.declineFriendRequest(connection.id)

        let pending = try await repo.fetchPendingRequests()
        #expect(pending.isEmpty)

        let friends = try await repo.fetchFriends()
        #expect(friends.isEmpty)
    }

    @Test("Fetch friends returns only accepted connections")
    func fetchFriendsReturnsOnlyAccepted() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let conn1 = try await repo.sendFriendRequest(toProfileId: "f-1", displayName: "Alice")
        let conn2 = try await repo.sendFriendRequest(toProfileId: "f-2", displayName: "Bob")
        _ = try await repo.sendFriendRequest(toProfileId: "f-3", displayName: "Charlie")

        try await repo.acceptFriendRequest(conn1.id)
        try await repo.acceptFriendRequest(conn2.id)

        let friends = try await repo.fetchFriends()
        #expect(friends.count == 2)

        let names = friends.map(\.friendDisplayName)
        #expect(names.contains("Alice"))
        #expect(names.contains("Bob"))
    }

    @Test("Fetch pending returns only pending connections")
    func fetchPendingReturnsOnlyPending() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let conn1 = try await repo.sendFriendRequest(toProfileId: "f-1", displayName: "Alice")
        _ = try await repo.sendFriendRequest(toProfileId: "f-2", displayName: "Bob")
        _ = try await repo.sendFriendRequest(toProfileId: "f-3", displayName: "Charlie")

        try await repo.acceptFriendRequest(conn1.id)

        let pending = try await repo.fetchPendingRequests()
        #expect(pending.count == 2)

        let names = pending.map(\.friendDisplayName)
        #expect(names.contains("Bob"))
        #expect(names.contains("Charlie"))
    }

    @Test("Remove friend deletes the connection")
    func removeFriendDeletesConnection() async throws {
        let container = try makeContainer()
        let repo = LocalFriendRepository(modelContainer: container)

        let conn = try await repo.sendFriendRequest(toProfileId: "friend-4", displayName: "Diana")
        try await repo.acceptFriendRequest(conn.id)

        let friendsBefore = try await repo.fetchFriends()
        #expect(friendsBefore.count == 1)

        try await repo.removeFriend(conn.id)

        let friendsAfter = try await repo.fetchFriends()
        #expect(friendsAfter.isEmpty)
    }
}
