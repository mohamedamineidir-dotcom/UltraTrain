import Foundation
import Testing
@testable import UltraTrain

@Suite("FinishEstimateSyncService Tests", .serialized)
struct FinishEstimateSyncServiceTests {

    // MARK: - Helpers

    private func makeSUT(
        authenticated: Bool = true
    ) -> (FinishEstimateSyncService, MockAuthService, FinishEstimateSyncTestURLProtocol.Type) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FinishEstimateSyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let remote = RemoteFinishEstimateDataSource(apiClient: apiClient)
        FinishEstimateSyncTestURLProtocol.reset()

        let sut = FinishEstimateSyncService(remote: remote, authService: auth)
        return (sut, auth, FinishEstimateSyncTestURLProtocol.self)
    }

    private func makeEstimate(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        expectedTime: TimeInterval = 36000,
        confidencePercent: Double = 72.0
    ) -> FinishEstimate {
        FinishEstimate(
            id: id,
            raceId: raceId,
            athleteId: UUID(),
            calculatedAt: Date(),
            optimisticTime: expectedTime * 0.9,
            expectedTime: expectedTime,
            conservativeTime: expectedTime * 1.15,
            checkpointSplits: [],
            confidencePercent: confidencePercent,
            raceResultsUsed: 3
        )
    }

    private func makeEstimateResponseJSON(estimate: FinishEstimate) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(estimate)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        {
            "id": "\(UUID().uuidString)",
            "estimate_id": "\(estimate.id.uuidString)",
            "race_id": "\(estimate.raceId.uuidString)",
            "expected_time": \(estimate.expectedTime),
            "confidence_percent": \(estimate.confidencePercent),
            "estimate_json": "\(escaped)",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    private func makePaginatedResponseJSON(estimate: FinishEstimate) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(estimate)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        {
            "items": [{
                "id": "\(UUID().uuidString)",
                "estimate_id": "\(estimate.id.uuidString)",
                "race_id": "\(estimate.raceId.uuidString)",
                "expected_time": \(estimate.expectedTime),
                "confidence_percent": \(estimate.confidencePercent),
                "estimate_json": "\(escaped)",
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": null,
            "has_more": false
        }
        """
    }

    // MARK: - syncEstimate

    @Test("syncEstimate uploads when authenticated")
    func syncUploadsWhenAuthenticated() async {
        let estimate = makeEstimate()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makeEstimateResponseJSON(estimate: estimate).utf8)
        proto.statusCode = 200

        await sut.syncEstimate(estimate)

        #expect(proto.requestCount > 0)
    }

    @Test("syncEstimate skips when not authenticated")
    func syncSkipsWhenNotAuthenticated() async {
        let estimate = makeEstimate()
        let (sut, _, proto) = makeSUT(authenticated: false)

        await sut.syncEstimate(estimate)

        #expect(proto.requestCount == 0)
    }

    @Test("syncEstimate handles remote error gracefully")
    func syncHandlesError() async {
        let estimate = makeEstimate()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await sut.syncEstimate(estimate)

        #expect(proto.requestCount > 0)
    }

    // MARK: - restoreEstimates

    @Test("restoreEstimates returns empty when not authenticated")
    func restoreEmptyWhenNotAuthenticated() async {
        let (sut, _, proto) = makeSUT(authenticated: false)

        let estimates = await sut.restoreEstimates()

        #expect(estimates.isEmpty)
        #expect(proto.requestCount == 0)
    }

    @Test("restoreEstimates returns empty on server error")
    func restoreEmptyOnError() async {
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        let estimates = await sut.restoreEstimates()

        #expect(estimates.isEmpty)
    }

    @Test("restoreEstimates returns decoded estimates from server")
    func restoreReturnsEstimates() async {
        let estimate = makeEstimate(expectedTime: 43200, confidencePercent: 80.0)
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makePaginatedResponseJSON(estimate: estimate).utf8)
        proto.statusCode = 200

        let estimates = await sut.restoreEstimates()

        #expect(estimates.count == 1)
        #expect(estimates.first?.id == estimate.id)
        #expect(estimates.first?.expectedTime == 43200)
        #expect(estimates.first?.confidencePercent == 80.0)
    }

    // MARK: - FinishEstimate model

    @Test("FinishEstimate expectedTimeFormatted formats hours and minutes")
    func expectedTimeFormatted() {
        let estimate = makeEstimate(expectedTime: 36900) // 10h15m
        #expect(estimate.expectedTimeFormatted == "10h15")
    }

    @Test("FinishEstimate formatDuration handles sub-hour values")
    func formatDurationSubHour() {
        let formatted = FinishEstimate.formatDuration(2700) // 45m
        #expect(formatted == "0h45")
    }
}

// MARK: - Stub URL Protocol

private final class FinishEstimateSyncTestURLProtocol: URLProtocol, @unchecked Sendable {
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
