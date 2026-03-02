import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("SyncedActivityFeedRepository Tests", .serialized)
@MainActor
struct SyncedActivityFeedRepositoryTests {

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

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ActivityFeedStubURLProtocol.self]
        let session = URLSession(configuration: config)
        return APIClient(
            baseURL: URL(string: "https://stub.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
    }

    private func makeActivity(
        title: String = "Morning run",
        timestamp: Date = Date()
    ) -> ActivityFeedItem {
        ActivityFeedItem(
            id: UUID(),
            athleteProfileId: "athlete-1",
            athleteDisplayName: "Runner",
            athletePhotoData: nil,
            activityType: .completedRun,
            title: title,
            subtitle: nil,
            stats: nil,
            timestamp: timestamp,
            likeCount: 0,
            isLikedByMe: false
        )
    }

    private func makeSUT(
        container: ModelContainer? = nil,
        authenticated: Bool = false,
        syncQueue: MockSyncQueueService? = nil
    ) throws -> (SyncedActivityFeedRepository, LocalActivityFeedRepository, MockAuthService) {
        let cont = try container ?? makeContainer()
        let local = LocalActivityFeedRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteActivityFeedDataSource(apiClient: makeStubAPIClient())
        let sut = SyncedActivityFeedRepository(
            local: local,
            remote: remote,
            authService: auth,
            syncQueue: syncQueue
        )
        return (sut, local, auth)
    }

    @Test("fetchFeed returns local data when not authenticated")
    func fetchFeedReturnsLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let activity = makeActivity(title: "Local run")
        try await local.publishActivity(activity)

        let feed = try await sut.fetchFeed(limit: 10)

        #expect(feed.count == 1)
        #expect(feed.first?.title == "Local run")
    }

    @Test("publishActivity saves locally even when not authenticated")
    func publishActivitySavesLocally() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)

        let activity = makeActivity(title: "Published run")
        try await sut.publishActivity(activity)

        let feed = try await local.fetchFeed(limit: 10)
        #expect(feed.count == 1)
        #expect(feed.first?.title == "Published run")
    }

    @Test("publishActivity enqueues sync when syncQueue is available")
    func publishActivityEnqueuesSyncWhenSyncQueueAvailable() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, _, _) = try makeSUT(authenticated: true, syncQueue: syncQueue)

        let activity = makeActivity()
        try await sut.publishActivity(activity)

        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .activityPublish && $0.entityId == activity.id
        }
        #expect(hasEnqueued)
    }

    @Test("toggleLike falls back to local when not authenticated")
    func toggleLikeFallsBackToLocalWhenNotAuthenticated() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let activity = makeActivity()
        try await local.publishActivity(activity)

        try await sut.toggleLike(itemId: activity.id)

        let feed = try await local.fetchFeed(limit: 10)
        #expect(feed.first?.isLikedByMe == true)
    }
}

// MARK: - Stub URL Protocol

private final class ActivityFeedStubURLProtocol: URLProtocol, @unchecked Sendable {
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
