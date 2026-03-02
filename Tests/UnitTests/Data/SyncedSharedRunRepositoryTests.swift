import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("SyncedSharedRunRepository Tests", .serialized)
@MainActor
struct SyncedSharedRunRepositoryTests {

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

    private func makeSharedRun(
        id: UUID = UUID(),
        distanceKm: Double = 21.1,
        sharedAt: Date = Date()
    ) -> SharedRun {
        SharedRun(
            id: id,
            sharedByProfileId: "runner-1",
            sharedByDisplayName: "Trail Runner",
            date: Date(),
            distanceKm: distanceKm,
            elevationGainM: 1200,
            elevationLossM: 1150,
            duration: 7200,
            averagePaceSecondsPerKm: 341,
            gpsTrack: [],
            splits: [],
            notes: nil,
            sharedAt: sharedAt,
            likeCount: 0,
            commentCount: 0
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SharedRunStubURLProtocol.self]
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
        authenticated: Bool = false,
        syncQueue: MockSyncQueueService? = nil
    ) throws -> (SyncedSharedRunRepository, LocalSharedRunRepository, MockAuthService) {
        let cont = try container ?? makeContainer()
        let local = LocalSharedRunRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteSharedRunDataSource(apiClient: makeStubAPIClient())
        let sut = SyncedSharedRunRepository(
            local: local,
            remote: remote,
            authService: auth,
            syncQueue: syncQueue
        )
        return (sut, local, auth)
    }

    @Test("fetchSharedRuns returns local data when not authenticated")
    func fetchSharedRunsReturnsLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let run = makeSharedRun(distanceKm: 42.0)
        try await local.shareRun(run, withFriendIds: [])

        let results = try await sut.fetchSharedRuns()

        #expect(results.count == 1)
        #expect(results.first?.distanceKm == 42.0)
    }

    @Test("shareRun saves locally when not authenticated")
    func shareRunSavesLocallyWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)

        let run = makeSharedRun(distanceKm: 15.0)
        try await sut.shareRun(run, withFriendIds: ["friend-1"])

        let results = try await local.fetchSharedRuns()
        #expect(results.count == 1)
    }

    @Test("revokeShare removes locally and enqueues sync when syncQueue available")
    func revokeShareEnqueuesSyncWhenSyncQueueAvailable() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(authenticated: true, syncQueue: syncQueue)
        let runId = UUID()

        try await local.shareRun(makeSharedRun(id: runId), withFriendIds: [])
        try await sut.revokeShare(runId)

        let results = try await local.fetchSharedRuns()
        #expect(results.isEmpty)

        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .shareRevoke && $0.entityId == runId
        }
        #expect(hasEnqueued)
    }

    @Test("fetchRunsSharedByMe returns local data when not authenticated")
    func fetchRunsSharedByMeReturnsLocalWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        try await local.shareRun(makeSharedRun(distanceKm: 10.0), withFriendIds: [])
        try await local.shareRun(makeSharedRun(distanceKm: 20.0), withFriendIds: [])

        let results = try await sut.fetchRunsSharedByMe()

        #expect(results.count == 2)
    }

    @Test("revokeShare removes locally without sync when not authenticated")
    func revokeShareRemovesLocallyWhenNotAuth() async throws {
        let (sut, local, _) = try makeSUT(authenticated: false)
        let runId = UUID()

        try await local.shareRun(makeSharedRun(id: runId), withFriendIds: [])
        try await sut.revokeShare(runId)

        let results = try await local.fetchSharedRuns()
        #expect(results.isEmpty)
    }
}

// MARK: - Stub URL Protocol

private final class SharedRunStubURLProtocol: URLProtocol, @unchecked Sendable {
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
