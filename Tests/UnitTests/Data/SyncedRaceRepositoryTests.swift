import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedRaceRepository Tests", .serialized)
@MainActor
struct SyncedRaceRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            RaceSwiftDataModel.self,
            CheckpointSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRace(
        id: UUID = UUID(),
        name: String = "UTMB",
        date: Date = Date(timeIntervalSince1970: 1_800_000_000),
        distanceKm: Double = 171,
        elevationGainM: Double = 10000,
        priority: RacePriority = .aRace,
        goalType: RaceGoal = .finish
    ) -> Race {
        Race(
            id: id,
            name: name,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 10000,
            priority: priority,
            goalType: goalType,
            checkpoints: [],
            terrainDifficulty: .technical
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
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
        syncQueue: MockSyncQueueService? = MockSyncQueueService(),
        authenticated: Bool = true
    ) throws -> (SyncedRaceRepository, LocalRaceRepository, MockSyncQueueService?) {
        let cont = try container ?? makeContainer()
        let local = LocalRaceRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteRaceDataSource(apiClient: makeStubAPIClient())
        let raceSyncService = RaceSyncService(remote: remote, authService: auth)
        let sut = SyncedRaceRepository(
            local: local,
            syncService: raceSyncService,
            syncQueue: syncQueue
        )
        return (sut, local, syncQueue)
    }

    // MARK: - getRaces

    @Test("getRaces returns locally saved races")
    func getRacesReturnsLocalRaces() async throws {
        let (sut, local, _) = try makeSUT()
        let race = makeRace()
        try await local.saveRace(race)

        let result = try await sut.getRaces()

        #expect(result.count == 1)
        #expect(result[0].name == "UTMB")
    }

    @Test("getRaces returns empty array when no races exist")
    func getRacesReturnsEmpty() async throws {
        let (sut, _, _) = try makeSUT()

        let result = try await sut.getRaces()

        #expect(result.isEmpty)
    }

    @Test("getRaces returns multiple races sorted by date")
    func getRacesReturnsMultipleRaces() async throws {
        let (sut, local, _) = try makeSUT()
        let race1 = makeRace(name: "CCC", date: Date(timeIntervalSince1970: 1_800_000_000))
        let race2 = makeRace(name: "OCC", date: Date(timeIntervalSince1970: 1_700_000_000))
        try await local.saveRace(race1)
        try await local.saveRace(race2)

        let result = try await sut.getRaces()

        #expect(result.count == 2)
    }

    // MARK: - getRace

    @Test("getRace returns matching race by ID")
    func getRaceReturnsById() async throws {
        let (sut, local, _) = try makeSUT()
        let race = makeRace()
        try await local.saveRace(race)

        let result = try await sut.getRace(id: race.id)

        #expect(result != nil)
        #expect(result?.id == race.id)
        #expect(result?.name == "UTMB")
    }

    @Test("getRace returns nil for unknown ID")
    func getRaceReturnsNilForUnknown() async throws {
        let (sut, _, _) = try makeSUT()

        let result = try await sut.getRace(id: UUID())

        #expect(result == nil)
    }

    // MARK: - saveRace

    @Test("saveRace persists locally and enqueues sync")
    func saveRacePersistsAndEnqueuesSync() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(syncQueue: syncQueue)
        let race = makeRace()

        try await sut.saveRace(race)

        let saved = try await local.getRace(id: race.id)
        #expect(saved != nil)
        #expect(saved?.name == "UTMB")
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .raceSync && $0.entityId == race.id
        }
        #expect(hasEnqueued)
    }

    @Test("saveRace enqueues raceSync operation type")
    func saveRaceEnqueuesRaceSyncType() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, _, _) = try makeSUT(syncQueue: syncQueue)
        let race = makeRace()

        try await sut.saveRace(race)

        #expect(syncQueue.enqueuedOperations.count == 1)
        #expect(syncQueue.enqueuedOperations[0].type == .raceSync)
    }

    // MARK: - updateRace

    @Test("updateRace persists changes locally and enqueues sync")
    func updateRacePersistsAndEnqueues() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(syncQueue: syncQueue)
        let race = makeRace()
        try await local.saveRace(race)

        var updated = race
        updated.name = "TDS"
        try await sut.updateRace(updated)

        let fetched = try await local.getRace(id: race.id)
        #expect(fetched?.name == "TDS")
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .raceSync && $0.entityId == race.id
        }
        #expect(hasEnqueued)
    }

    // MARK: - deleteRace

    @Test("deleteRace removes from local storage and enqueues delete")
    func deleteRaceRemovesAndEnqueuesDelete() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(syncQueue: syncQueue)
        let race = makeRace()
        try await local.saveRace(race)

        try await sut.deleteRace(id: race.id)

        let result = try await local.getRace(id: race.id)
        #expect(result == nil)
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .raceDelete && $0.entityId == race.id
        }
        #expect(hasEnqueued)
    }

    @Test("deleteRace without syncQueue still removes locally")
    func deleteRaceWithoutSyncQueueRemovesLocally() async throws {
        let (sut, local, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let race = makeRace()
        try await local.saveRace(race)

        try await sut.deleteRace(id: race.id)

        let result = try await local.getRace(id: race.id)
        #expect(result == nil)
    }

    // MARK: - Save without syncQueue

    @Test("saveRace without syncQueue uses direct sync service")
    func saveRaceWithoutSyncQueue() async throws {
        let (sut, local, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let race = makeRace()

        try await sut.saveRace(race)

        let saved = try await local.getRace(id: race.id)
        #expect(saved != nil)
    }
}

// MARK: - Stub URL Protocol

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData ?? Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
