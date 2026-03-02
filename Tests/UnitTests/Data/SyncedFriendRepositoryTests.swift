import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("SyncedFriendRepository Tests", .serialized)
@MainActor
struct SyncedFriendRepositoryTests {

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

    private func makeFriendConnection(
        id: UUID = UUID(),
        friendProfileId: String = "friend-1",
        displayName: String = "Trail Buddy",
        status: FriendStatus = .accepted
    ) -> FriendConnection {
        FriendConnection(
            id: id,
            friendProfileId: friendProfileId,
            friendDisplayName: displayName,
            friendPhotoData: nil,
            status: status,
            createdDate: Date(),
            acceptedDate: status == .accepted ? Date() : nil
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FriendStubURLProtocol.self]
        let session = URLSession(configuration: config)
        return APIClient(
            baseURL: URL(string: "https://stub.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
    }

    private func makeSUT(
        container: ModelContainer? = nil,
        authenticated: Bool = false
    ) throws -> (SyncedFriendRepository, LocalFriendRepository, MockAuthService) {
        let cont = try container ?? makeContainer()
        let local = LocalFriendRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteFriendDataSource(apiClient: makeStubAPIClient())
        let sut = SyncedFriendRepository(
            local: local,
            remote: remote,
            authService: auth
        )
        return (sut, local, auth)
    }

    @Test("fetchFriends returns local data when not authenticated")
    func fetchFriendsReturnsLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        // Use sendFriendRequest to create a connection, then accept it
        let conn = try await local.sendFriendRequest(toProfileId: "friend-1", displayName: "Local Friend")
        try await local.acceptFriendRequest(conn.id)

        let friends = try await sut.fetchFriends()

        #expect(friends.count == 1)
        #expect(friends.first?.friendDisplayName == "Local Friend")
    }

    @Test("fetchPendingRequests returns local data when not authenticated")
    func fetchPendingReturnsLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        _ = try await local.sendFriendRequest(toProfileId: "pending-1", displayName: "Pending Friend")

        let results = try await sut.fetchPendingRequests()

        #expect(results.count == 1)
        #expect(results.first?.status == .pending)
    }

    @Test("sendFriendRequest creates local connection when not authenticated")
    func sendFriendRequestCreatesLocalWhenNotAuthenticated() async throws {
        let (sut, _, _) = try makeSUT(authenticated: false)

        let result = try await sut.sendFriendRequest(toProfileId: "new-friend", displayName: "New Runner")

        #expect(result.friendProfileId == "new-friend")
        #expect(result.friendDisplayName == "New Runner")
        #expect(result.status == .pending)
    }

    @Test("acceptFriendRequest updates local when not authenticated")
    func acceptFriendRequestUpdatesLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let conn = try await local.sendFriendRequest(toProfileId: "to-accept", displayName: "Accept Me")

        try await sut.acceptFriendRequest(conn.id)

        let friends = try await local.fetchFriends()
        let accepted = friends.first { $0.id == conn.id }
        #expect(accepted?.status == .accepted)
    }

    @Test("removeFriend removes local connection when not authenticated")
    func removeFriendRemovesLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let conn = try await local.sendFriendRequest(toProfileId: "to-remove", displayName: "Remove Me")
        try await local.acceptFriendRequest(conn.id)

        try await sut.removeFriend(conn.id)

        let friends = try await local.fetchFriends()
        #expect(friends.isEmpty)
    }
}

// MARK: - Stub URL Protocol

private final class FriendStubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
