import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedTrainingPlanRepository Tests", .serialized)
@MainActor
struct SyncedTrainingPlanRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TrainingPlanSwiftDataModel.self,
            TrainingWeekSwiftDataModel.self,
            TrainingSessionSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSession(
        id: UUID = UUID(),
        date: Date = Date(),
        type: SessionType = .longRun
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 10800,
            intensity: .moderate,
            description: "Long trail run",
            isCompleted: false,
            isSkipped: false
        )
    }

    private func makePlan(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        targetRaceId: UUID = UUID(),
        sessions: [TrainingSession]? = nil
    ) -> TrainingPlan {
        let actualSessions = sessions ?? [makeSession()]
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date(),
            endDate: Date().adding(days: 6),
            phase: .base,
            sessions: actualSessions,
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 2000
        )
        return TrainingPlan(
            id: id,
            athleteId: athleteId,
            targetRaceId: targetRaceId,
            createdAt: Date(),
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TrainingPlanStubURLProtocol.self]
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
    ) throws -> (SyncedTrainingPlanRepository, LocalTrainingPlanRepository, MockSyncQueueService?) {
        let cont = try container ?? makeContainer()
        let local = LocalTrainingPlanRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let raceRepo = MockRaceRepository()
        let remoteDS = RemoteTrainingPlanDataSource(apiClient: makeStubAPIClient())
        let syncService = TrainingPlanSyncService(
            remote: remoteDS,
            raceRepository: raceRepo,
            authService: auth
        )
        let sut = SyncedTrainingPlanRepository(
            local: local,
            syncService: syncService,
            syncQueue: syncQueue
        )
        return (sut, local, syncQueue)
    }

    // MARK: - getActivePlan

    @Test("getActivePlan returns locally stored plan")
    func getActivePlanReturnsLocalPlan() async throws {
        let (sut, local, _) = try makeSUT()
        let plan = makePlan()
        try await local.savePlan(plan)

        let result = try await sut.getActivePlan()

        #expect(result != nil)
        #expect(result?.id == plan.id)
    }

    @Test("getActivePlan returns nil when no plan exists and not authenticated")
    func getActivePlanReturnsNilWhenNoLocalAndNotAuth() async throws {
        let (sut, _, _) = try makeSUT(authenticated: false)

        let result = try await sut.getActivePlan()

        #expect(result == nil)
    }

    // MARK: - getPlan

    @Test("getPlan returns plan by ID")
    func getPlanReturnsById() async throws {
        let (sut, local, _) = try makeSUT()
        let plan = makePlan()
        try await local.savePlan(plan)

        let result = try await sut.getPlan(id: plan.id)

        #expect(result != nil)
        #expect(result?.id == plan.id)
    }

    @Test("getPlan returns nil for unknown ID")
    func getPlanReturnsNilForUnknown() async throws {
        let (sut, _, _) = try makeSUT()

        let result = try await sut.getPlan(id: UUID())

        #expect(result == nil)
    }

    // MARK: - savePlan

    @Test("savePlan persists locally and enqueues sync")
    func savePlanPersistsAndEnqueues() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(syncQueue: syncQueue)
        let plan = makePlan()

        try await sut.savePlan(plan)

        let saved = try await local.getActivePlan()
        #expect(saved != nil)
        #expect(saved?.id == plan.id)
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .trainingPlanSync && $0.entityId == plan.id
        }
        #expect(hasEnqueued)
    }

    @Test("savePlan enqueues trainingPlanSync operation type")
    func savePlanEnqueuesCorrectType() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, _, _) = try makeSUT(syncQueue: syncQueue)
        let plan = makePlan()

        try await sut.savePlan(plan)

        #expect(syncQueue.enqueuedOperations.count == 1)
        #expect(syncQueue.enqueuedOperations[0].type == .trainingPlanSync)
        #expect(syncQueue.enqueuedOperations[0].entityId == plan.id)
    }

    // MARK: - updatePlan

    @Test("updatePlan persists changes locally and enqueues sync")
    func updatePlanPersistsAndEnqueues() async throws {
        let syncQueue = MockSyncQueueService()
        let (sut, local, _) = try makeSUT(syncQueue: syncQueue)
        let plan = makePlan()
        try await local.savePlan(plan)

        let session2 = makeSession(type: .intervals)
        var updated = plan
        updated.weeks[0].sessions.append(session2)
        try await sut.updatePlan(updated)

        let fetched = try await local.getActivePlan()
        #expect(fetched != nil)
        #expect(fetched?.weeks[0].sessions.count == 2)
        let hasEnqueued = syncQueue.enqueuedOperations.contains {
            $0.type == .trainingPlanSync && $0.entityId == plan.id
        }
        #expect(hasEnqueued)
    }

    // MARK: - updateSession

    @Test("updateSession persists session changes locally")
    func updateSessionPersistsLocally() async throws {
        let sessionId = UUID()
        let session = makeSession(id: sessionId)
        let (sut, local, _) = try makeSUT()
        let plan = makePlan(sessions: [session])
        try await local.savePlan(plan)

        var updatedSession = session
        updatedSession.isCompleted = true
        try await sut.updateSession(updatedSession)

        let fetched = try await local.getActivePlan()
        let fetchedSession = fetched?.weeks.first?.sessions.first { $0.id == sessionId }
        #expect(fetchedSession?.isCompleted == true)
    }

    // MARK: - Save without syncQueue

    @Test("savePlan without syncQueue uses direct sync service")
    func savePlanWithoutSyncQueue() async throws {
        let (sut, local, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let plan = makePlan()

        try await sut.savePlan(plan)

        let saved = try await local.getActivePlan()
        #expect(saved != nil)
    }

    @Test("updatePlan without syncQueue uses direct sync service")
    func updatePlanWithoutSyncQueue() async throws {
        let (sut, local, _) = try makeSUT(syncQueue: nil, authenticated: false)
        let plan = makePlan()
        try await local.savePlan(plan)

        try await sut.updatePlan(plan)

        let fetched = try await local.getActivePlan()
        #expect(fetched != nil)
    }
}

// MARK: - Stub URL Protocol

private final class TrainingPlanStubURLProtocol: URLProtocol, @unchecked Sendable {
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
