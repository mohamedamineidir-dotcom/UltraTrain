import Foundation
import Testing
@testable import UltraTrain

@Suite("TrainingPlanSyncService Tests", .serialized)
struct TrainingPlanSyncServiceTests {

    // MARK: - Helpers

    private func makeSUT(
        authenticated: Bool = true,
        raceRepository: MockRaceRepository? = nil
    ) -> (TrainingPlanSyncService, MockAuthService, TrainingPlanSyncTestURLProtocol.Type, MockRaceRepository) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TrainingPlanSyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let remote = RemoteTrainingPlanDataSource(apiClient: apiClient)
        let raceRepo = raceRepository ?? MockRaceRepository()
        TrainingPlanSyncTestURLProtocol.reset()

        let sut = TrainingPlanSyncService(
            remote: remote,
            raceRepository: raceRepo,
            authService: auth
        )
        return (sut, auth, TrainingPlanSyncTestURLProtocol.self, raceRepo)
    }

    private func makePlan(
        id: UUID = UUID(),
        targetRaceId: UUID = UUID()
    ) -> TrainingPlan {
        TrainingPlan(
            id: id,
            athleteId: UUID(),
            targetRaceId: targetRaceId,
            createdAt: Date(),
            weeks: [],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func makeRace(id: UUID, name: String = "UTMB") -> Race {
        Race(
            id: id,
            name: name,
            date: Date().addingTimeInterval(86400 * 60),
            distanceKm: 171.0,
            elevationGainM: 10000.0,
            elevationLossM: 10000.0,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical
        )
    }

    private func makePlanResponseJSON(plan: TrainingPlan) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(plan)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let formatter = ISO8601DateFormatter()

        return """
        {
            "id": "\(UUID().uuidString)",
            "target_race_name": "UTMB",
            "target_race_date": "\(formatter.string(from: Date()))",
            "total_weeks": \(plan.weeks.count),
            "plan_json": "\(escaped)",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    // MARK: - syncPlan

    @Test("syncPlan uploads plan when authenticated with valid race")
    func syncUploadsWhenAuthenticated() async {
        let raceId = UUID()
        let plan = makePlan(targetRaceId: raceId)
        let race = makeRace(id: raceId, name: "Trail des Templiers")

        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let (sut, _, proto, _) = makeSUT(authenticated: true, raceRepository: raceRepo)
        proto.responseData = Data(makePlanResponseJSON(plan: plan).utf8)
        proto.statusCode = 200

        await sut.syncPlan(plan)

        #expect(proto.requestCount > 0)
    }

    @Test("syncPlan skips when not authenticated")
    func syncSkipsWhenNotAuthenticated() async {
        let plan = makePlan()
        let (sut, _, proto, _) = makeSUT(authenticated: false)

        await sut.syncPlan(plan)

        #expect(proto.requestCount == 0)
    }

    @Test("syncPlan handles remote error gracefully")
    func syncHandlesError() async {
        let raceId = UUID()
        let plan = makePlan(targetRaceId: raceId)
        let race = makeRace(id: raceId)

        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let (sut, _, proto, _) = makeSUT(
            authenticated: true,
            raceRepository: raceRepo
        )
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await sut.syncPlan(plan)

        #expect(proto.requestCount > 0)
    }

    @Test("syncPlan still uploads when race not found in local repository")
    func syncStillUploadsWhenRaceNotFoundLocally() async {
        let plan = makePlan(targetRaceId: UUID())
        let (sut, _, proto, _) = makeSUT(authenticated: true)
        proto.responseData = Data(makePlanResponseJSON(plan: plan).utf8)
        proto.statusCode = 200

        await sut.syncPlan(plan)

        // Service uses "Unknown Race" as fallback when race not found
        #expect(proto.requestCount > 0)
    }

    // MARK: - restorePlan

    @Test("restorePlan returns nil when not authenticated")
    func restoreNilWhenNotAuthenticated() async {
        let (sut, _, proto, _) = makeSUT(authenticated: false)

        let plan = await sut.restorePlan()

        #expect(plan == nil)
        #expect(proto.requestCount == 0)
    }

    @Test("restorePlan returns nil on server error")
    func restoreNilOnError() async {
        let (sut, _, proto, _) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        let plan = await sut.restorePlan()

        #expect(plan == nil)
    }

    @Test("restorePlan returns decoded plan from server")
    func restoreReturnsPlan() async {
        let originalPlan = makePlan()
        let (sut, _, proto, _) = makeSUT(authenticated: true)
        proto.responseData = Data(makePlanResponseJSON(plan: originalPlan).utf8)
        proto.statusCode = 200

        let plan = await sut.restorePlan()

        #expect(plan != nil)
        #expect(plan?.id == originalPlan.id)
        #expect(plan?.targetRaceId == originalPlan.targetRaceId)
    }

    @Test("restorePlan returns nil when server returns invalid plan JSON")
    func restoreReturnsNilForInvalidJSON() async {
        let (sut, _, proto, _) = makeSUT(authenticated: true)
        let invalidJSON = """
        {
            "id": "\(UUID().uuidString)",
            "target_race_name": "Bad Race",
            "target_race_date": "2026-06-01T00:00:00Z",
            "total_weeks": 8,
            "plan_json": "{ invalid json",
            "created_at": null,
            "updated_at": null
        }
        """
        proto.responseData = Data(invalidJSON.utf8)
        proto.statusCode = 200

        let plan = await sut.restorePlan()

        #expect(plan == nil)
    }
}

// MARK: - Stub URL Protocol

private final class TrainingPlanSyncTestURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var requestCount: Int = 0

    static func reset() {
        responseData = nil
        statusCode = 200
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
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
