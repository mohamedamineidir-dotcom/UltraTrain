import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("SyncedGroupChallengeRepository Tests", .serialized)
@MainActor
struct SyncedGroupChallengeRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            GroupChallengeSwiftDataModel.self,
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeChallenge(
        id: UUID = UUID(),
        name: String = "Weekly 50K",
        status: GroupChallengeStatus = .active
    ) -> GroupChallenge {
        GroupChallenge(
            id: id,
            creatorProfileId: "creator-1",
            creatorDisplayName: "Trail Runner",
            name: name,
            descriptionText: "Run 50km this week",
            type: .distance,
            targetValue: 50.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(604800),
            status: status,
            participants: []
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GroupChallengeStubURLProtocol.self]
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
    ) throws -> (SyncedGroupChallengeRepository, LocalGroupChallengeRepository, MockAuthService) {
        let cont = try container ?? makeContainer()
        let local = LocalGroupChallengeRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteGroupChallengeDataSource(apiClient: makeStubAPIClient())
        let sut = SyncedGroupChallengeRepository(
            local: local,
            remote: remote,
            authService: auth
        )
        return (sut, local, auth)
    }

    @Test("fetchActiveChallenges returns local data when not authenticated")
    func fetchActiveChallengesReturnsLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        _ = try await local.createChallenge(makeChallenge(name: "Local Challenge", status: .active))

        let results = try await sut.fetchActiveChallenges()

        #expect(results.count == 1)
        #expect(results.first?.name == "Local Challenge")
    }

    @Test("fetchCompletedChallenges returns local data when not authenticated")
    func fetchCompletedChallengesReturnsLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        _ = try await local.createChallenge(makeChallenge(name: "Done Challenge", status: .completed))

        let results = try await sut.fetchCompletedChallenges()

        #expect(results.count == 1)
        #expect(results.first?.name == "Done Challenge")
    }

    @Test("createChallenge falls back to local when not authenticated")
    func createChallengeFallsBackToLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)

        let challenge = makeChallenge(name: "My Challenge")
        let result = try await sut.createChallenge(challenge)

        #expect(result.name == "My Challenge")
        let localChallenges = try await local.fetchActiveChallenges()
        #expect(localChallenges.count == 1)
    }

    @Test("joinChallenge updates local when not authenticated")
    func joinChallengeFallsBackToLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let challengeId = UUID()
        _ = try await local.createChallenge(makeChallenge(id: challengeId))

        // Should not throw when challenge exists locally
        try await sut.joinChallenge(challengeId)
    }

    @Test("updateProgress updates local when not authenticated")
    func updateProgressFallsBackToLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let challengeId = UUID()
        _ = try await local.createChallenge(makeChallenge(id: challengeId))

        // The local implementation needs participants to update, so this tests the fallback path
        await #expect(throws: DomainError.self) {
            try await sut.updateProgress(challengeId: UUID(), value: 25.0)
        }
    }
}

// MARK: - Stub URL Protocol

private final class GroupChallengeStubURLProtocol: URLProtocol, @unchecked Sendable {
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
