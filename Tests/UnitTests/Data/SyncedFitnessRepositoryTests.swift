import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedFitnessRepository Tests", .serialized)
@MainActor
struct SyncedFitnessRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([FitnessSnapshotSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSnapshot(
        id: UUID = UUID(),
        date: Date = Date(),
        fitness: Double = 45.0,
        fatigue: Double = 30.0,
        form: Double = 15.0,
        weeklyVolumeKm: Double = 80,
        weeklyElevationGainM: Double = 3000,
        weeklyDuration: TimeInterval = 36000,
        acuteToChronicRatio: Double = 1.1,
        monotony: Double = 1.5
    ) -> FitnessSnapshot {
        FitnessSnapshot(
            id: id,
            date: date,
            fitness: fitness,
            fatigue: fatigue,
            form: form,
            weeklyVolumeKm: weeklyVolumeKm,
            weeklyElevationGainM: weeklyElevationGainM,
            weeklyDuration: weeklyDuration,
            acuteToChronicRatio: acuteToChronicRatio,
            monotony: monotony
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FitnessStubURLProtocol.self]
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
    ) throws -> (SyncedFitnessRepository, LocalFitnessRepository) {
        let cont = try container ?? makeContainer()
        let local = LocalFitnessRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteFitnessDataSource(apiClient: makeStubAPIClient())
        let syncService = FitnessSyncService(remote: remote, authService: auth)
        let sut = SyncedFitnessRepository(local: local, syncService: syncService)
        return (sut, local)
    }

    // MARK: - getLatestSnapshot

    @Test("getLatestSnapshot returns locally stored snapshot")
    func getLatestSnapshotReturnsLocal() async throws {
        let (sut, local) = try makeSUT()
        let snapshot = makeSnapshot(fitness: 55.0)
        try await local.saveSnapshot(snapshot)

        let result = try await sut.getLatestSnapshot()

        #expect(result != nil)
        #expect(result?.fitness == 55.0)
    }

    @Test("getLatestSnapshot returns nil when no snapshots exist")
    func getLatestSnapshotReturnsNilWhenEmpty() async throws {
        let (sut, _) = try makeSUT()

        let result = try await sut.getLatestSnapshot()

        #expect(result == nil)
    }

    // MARK: - getSnapshots

    @Test("getSnapshots returns locally stored snapshots in date range")
    func getSnapshotsReturnsLocalInRange() async throws {
        let (sut, local) = try makeSUT()
        let now = Date.now
        let snap1 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
            fitness: 40.0
        )
        let snap2 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            fitness: 50.0
        )
        try await local.saveSnapshot(snap1)
        try await local.saveSnapshot(snap2)

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let result = try await sut.getSnapshots(from: startDate, to: now)

        #expect(result.count == 2)
    }

    @Test("getSnapshots returns empty when no local data and not authenticated")
    func getSnapshotsReturnsEmptyWhenNoLocalAndNotAuth() async throws {
        let (sut, _) = try makeSUT(authenticated: false)
        let now = Date.now
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let result = try await sut.getSnapshots(from: startDate, to: now)

        #expect(result.isEmpty)
    }

    // MARK: - saveSnapshot

    @Test("saveSnapshot persists locally")
    func saveSnapshotPersistsLocally() async throws {
        let (sut, local) = try makeSUT()
        let snapshot = makeSnapshot(fitness: 60.0, fatigue: 35.0, form: 25.0)

        try await sut.saveSnapshot(snapshot)

        let fetched = try await local.getLatestSnapshot()
        #expect(fetched != nil)
        #expect(fetched?.fitness == 60.0)
        #expect(fetched?.fatigue == 35.0)
        #expect(fetched?.form == 25.0)
    }

    @Test("saveSnapshot preserves all fields through synced repository")
    func saveSnapshotPreservesAllFields() async throws {
        let (sut, local) = try makeSUT()
        let snapshot = makeSnapshot(
            fitness: 70.0,
            fatigue: 50.0,
            form: 20.0,
            weeklyVolumeKm: 120,
            weeklyElevationGainM: 5000,
            weeklyDuration: 54000,
            acuteToChronicRatio: 1.4,
            monotony: 1.9
        )

        try await sut.saveSnapshot(snapshot)

        let fetched = try await local.getLatestSnapshot()
        #expect(fetched?.weeklyVolumeKm == 120)
        #expect(fetched?.weeklyElevationGainM == 5000)
        #expect(fetched?.acuteToChronicRatio == 1.4)
        #expect(fetched?.monotony == 1.9)
    }

    @Test("Multiple snapshots saved and latest returned correctly")
    func multipleSnapshotsSavedCorrectly() async throws {
        let (sut, _) = try makeSUT()

        let older = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
            fitness: 40.0
        )
        let newer = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            fitness: 55.0
        )
        try await sut.saveSnapshot(older)
        try await sut.saveSnapshot(newer)

        let latest = try await sut.getLatestSnapshot()
        #expect(latest?.fitness == 55.0)
    }
}

// MARK: - Stub URL Protocol

private final class FitnessStubURLProtocol: URLProtocol, @unchecked Sendable {
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
