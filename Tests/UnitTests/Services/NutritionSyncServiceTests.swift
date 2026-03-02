import Foundation
import Testing
@testable import UltraTrain

@Suite("NutritionSyncService Tests", .serialized)
struct NutritionSyncServiceTests {

    // MARK: - Helpers

    private func makeSUT(
        authenticated: Bool = true
    ) -> (NutritionSyncService, MockAuthService, NutritionSyncTestURLProtocol.Type) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NutritionSyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let remote = RemoteNutritionDataSource(apiClient: apiClient)
        NutritionSyncTestURLProtocol.reset()

        let sut = NutritionSyncService(remote: remote, authService: auth)
        return (sut, auth, NutritionSyncTestURLProtocol.self)
    }

    private func makePlan(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        caloriesPerHour: Int = 300
    ) -> NutritionPlan {
        NutritionPlan(
            id: id,
            raceId: raceId,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: 600,
            sodiumMgPerHour: 500,
            entries: [],
            gutTrainingSessionIds: []
        )
    }

    private func makeNutritionResponseJSON(plan: NutritionPlan) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(plan)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        {
            "id": "\(UUID().uuidString)",
            "nutrition_plan_id": "\(plan.id.uuidString)",
            "race_id": "\(plan.raceId.uuidString)",
            "calories_per_hour": \(plan.caloriesPerHour),
            "nutrition_json": "\(escaped)",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    private func makePaginatedResponseJSON(plan: NutritionPlan) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(plan)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        {
            "items": [{
                "id": "\(UUID().uuidString)",
                "nutrition_plan_id": "\(plan.id.uuidString)",
                "race_id": "\(plan.raceId.uuidString)",
                "calories_per_hour": \(plan.caloriesPerHour),
                "nutrition_json": "\(escaped)",
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": null,
            "has_more": false
        }
        """
    }

    // MARK: - syncNutrition

    @Test("syncNutrition uploads plan when authenticated")
    func syncUploadsWhenAuthenticated() async {
        let plan = makePlan()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makeNutritionResponseJSON(plan: plan).utf8)
        proto.statusCode = 200

        await sut.syncNutrition(plan)

        #expect(proto.requestCount > 0)
    }

    @Test("syncNutrition does nothing when not authenticated")
    func syncSkipsWhenNotAuthenticated() async {
        let plan = makePlan()
        let (sut, _, proto) = makeSUT(authenticated: false)

        await sut.syncNutrition(plan)

        #expect(proto.requestCount == 0)
    }

    @Test("syncNutrition does not crash when remote returns error")
    func syncHandlesRemoteError() async {
        let plan = makePlan()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        // Should not throw — errors are caught internally
        await sut.syncNutrition(plan)

        #expect(proto.requestCount > 0)
    }

    // MARK: - restoreNutrition

    @Test("restoreNutrition returns empty array when not authenticated")
    func restoreReturnsEmptyWhenNotAuthenticated() async {
        let (sut, _, proto) = makeSUT(authenticated: false)

        let plans = await sut.restoreNutrition()

        #expect(plans.isEmpty)
        #expect(proto.requestCount == 0)
    }

    @Test("restoreNutrition returns empty array on server error")
    func restoreReturnsEmptyOnError() async {
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        let plans = await sut.restoreNutrition()

        #expect(plans.isEmpty)
    }

    @Test("restoreNutrition returns decoded plans from server")
    func restoreReturnsPlansfromRemote() async {
        let plan = makePlan(caloriesPerHour: 350)
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makePaginatedResponseJSON(plan: plan).utf8)
        proto.statusCode = 200

        let plans = await sut.restoreNutrition()

        #expect(plans.count == 1)
        #expect(plans.first?.id == plan.id)
        #expect(plans.first?.caloriesPerHour == 350)
    }
}

// MARK: - Stub URL Protocol

private final class NutritionSyncTestURLProtocol: URLProtocol, @unchecked Sendable {
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
