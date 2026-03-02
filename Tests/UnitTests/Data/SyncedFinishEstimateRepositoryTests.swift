import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("SyncedFinishEstimateRepository Tests", .serialized)
@MainActor
struct SyncedFinishEstimateRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([FinishEstimateSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeEstimate(
        raceId: UUID = UUID(),
        expectedTime: TimeInterval = 43200
    ) -> FinishEstimate {
        FinishEstimate(
            id: UUID(),
            raceId: raceId,
            athleteId: UUID(),
            calculatedAt: Date(),
            optimisticTime: 36000,
            expectedTime: expectedTime,
            conservativeTime: 50400,
            checkpointSplits: [],
            confidencePercent: 75.0,
            raceResultsUsed: 3
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FinishEstimateStubURLProtocol.self]
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
    ) throws -> (SyncedFinishEstimateRepository, LocalFinishEstimateRepository) {
        let cont = try container ?? makeContainer()
        let local = LocalFinishEstimateRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteFinishEstimateDataSource(apiClient: makeStubAPIClient())
        let syncService = FinishEstimateSyncService(remote: remote, authService: auth)
        let sut = SyncedFinishEstimateRepository(local: local, syncService: syncService)
        return (sut, local)
    }

    @Test("getEstimate returns locally stored estimate")
    func getEstimateReturnsLocal() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()
        let estimate = makeEstimate(raceId: raceId, expectedTime: 40000)
        try await local.saveEstimate(estimate)

        let result = try await sut.getEstimate(for: raceId)

        #expect(result != nil)
        #expect(result?.expectedTime == 40000)
    }

    @Test("getEstimate returns nil when no local data and not authenticated")
    func getEstimateReturnsNilWhenNoLocalAndNotAuth() async throws {
        let (sut, _) = try makeSUT(authenticated: false)

        let result = try await sut.getEstimate(for: UUID())

        #expect(result == nil)
    }

    @Test("saveEstimate persists locally")
    func saveEstimatePersistsLocally() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()
        let estimate = makeEstimate(raceId: raceId, expectedTime: 38000)

        try await sut.saveEstimate(estimate)

        let fetched = try await local.getEstimate(for: raceId)
        #expect(fetched != nil)
        #expect(fetched?.expectedTime == 38000)
    }

    @Test("saveEstimate overwrites previous estimate for same race")
    func saveEstimateOverwritesPrevious() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()

        try await sut.saveEstimate(makeEstimate(raceId: raceId, expectedTime: 40000))
        try await sut.saveEstimate(makeEstimate(raceId: raceId, expectedTime: 35000))

        let fetched = try await local.getEstimate(for: raceId)
        #expect(fetched?.expectedTime == 35000)
    }
}

// MARK: - Stub URL Protocol

private final class FinishEstimateStubURLProtocol: URLProtocol, @unchecked Sendable {
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
        client?.urlProtocol(self, didLoad: Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
