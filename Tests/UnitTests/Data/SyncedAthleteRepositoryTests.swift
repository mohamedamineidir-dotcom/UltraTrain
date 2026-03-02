import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedAthleteRepository Tests", .serialized)
@MainActor
struct SyncedAthleteRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([AthleteSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeAthlete(
        id: UUID = UUID(),
        firstName: String = "Kilian",
        lastName: String = "Jornet",
        experienceLevel: ExperienceLevel = .elite,
        weightKg: Double = 58,
        weeklyVolumeKm: Double = 120
    ) -> Athlete {
        Athlete(
            id: id,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: Date(timeIntervalSince1970: 536_457_600),
            weightKg: weightKg,
            heightCm: 171,
            restingHeartRate: 42,
            maxHeartRate: 195,
            experienceLevel: experienceLevel,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: 170,
            preferredUnit: .metric
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AthleteStubURLProtocol.self]
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
        authenticated: Bool = false
    ) throws -> (SyncedAthleteRepository, LocalAthleteRepository, MockSyncQueueService?, MockAuthService) {
        let cont = try container ?? makeContainer()
        let local = LocalAthleteRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteAthleteDataSource(apiClient: makeStubAPIClient())
        let sut = SyncedAthleteRepository(
            local: local,
            remote: remote,
            authService: auth,
            syncQueue: syncQueue
        )
        return (sut, local, syncQueue, auth)
    }

    // MARK: - getAthlete

    @Test("getAthlete returns locally saved athlete")
    func getAthleteReturnsLocalAthlete() async throws {
        let (sut, local, _, _) = try makeSUT()
        let athlete = makeAthlete()
        try await local.saveAthlete(athlete)

        let result = try await sut.getAthlete()

        #expect(result != nil)
        #expect(result?.firstName == "Kilian")
        #expect(result?.lastName == "Jornet")
    }

    @Test("getAthlete returns nil when no local data and not authenticated")
    func getAthleteReturnsNilWhenEmptyAndNotAuth() async throws {
        let (sut, _, _, _) = try makeSUT(authenticated: false)

        let result = try await sut.getAthlete()

        #expect(result == nil)
    }

    // MARK: - saveAthlete

    @Test("saveAthlete persists locally and enqueues sync")
    func saveAthletePersistsAndEnqueuesSync() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _, _) = try makeSUT(syncQueue: syncQueue, authenticated: true)
        let athlete = makeAthlete()

        try await sut.saveAthlete(athlete)

        let saved = try await local.getAthlete()
        #expect(saved != nil)
        #expect(saved?.firstName == "Kilian")
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .athleteSync && $0.entityId == athlete.id
        }
        #expect(hasEnqueued)
    }

    @Test("saveAthlete enqueues athleteSync operation type")
    func saveAthleteEnqueuesCorrectType() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, _, _, _) = try makeSUT(syncQueue: syncQueue)
        let athlete = makeAthlete()

        try await sut.saveAthlete(athlete)

        #expect(syncQueue.enqueuedOperations.count == 1)
        #expect(syncQueue.enqueuedOperations[0].type == .athleteSync)
        #expect(syncQueue.enqueuedOperations[0].entityId == athlete.id)
    }

    @Test("saveAthlete without syncQueue still saves locally")
    func saveAthleteWithoutSyncQueueSavesLocally() async throws {
        let (sut, local, _, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let athlete = makeAthlete()

        try await sut.saveAthlete(athlete)

        let saved = try await local.getAthlete()
        #expect(saved != nil)
    }

    // MARK: - updateAthlete

    @Test("updateAthlete persists changes locally and enqueues sync")
    func updateAthletePersistsAndEnqueues() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _, _) = try makeSUT(syncQueue: syncQueue)
        let athleteId = UUID()
        let athlete = makeAthlete(id: athleteId, firstName: "Jim")
        try await local.saveAthlete(athlete)

        let updated = makeAthlete(id: athleteId, firstName: "Jim-Updated", weightKg: 62)
        try await sut.updateAthlete(updated)

        let fetched = try await local.getAthlete()
        #expect(fetched?.firstName == "Jim-Updated")
        #expect(fetched?.weightKg == 62)
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .athleteSync && $0.entityId == athleteId
        }
        #expect(hasEnqueued)
    }

    @Test("updateAthlete without syncQueue still updates locally")
    func updateAthleteWithoutSyncQueue() async throws {
        let (sut, local, _, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let athleteId = UUID()
        let athlete = makeAthlete(id: athleteId, firstName: "Before")
        try await local.saveAthlete(athlete)

        let updated = makeAthlete(id: athleteId, firstName: "After")
        try await sut.updateAthlete(updated)

        let fetched = try await local.getAthlete()
        #expect(fetched?.firstName == "After")
    }
}

// MARK: - Stub URL Protocol

private final class AthleteStubURLProtocol: URLProtocol, @unchecked Sendable {
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
