import Foundation
import Testing
@testable import UltraTrain

@Suite("RemoteRunDataSource Tests", .serialized)
struct RemoteRunDataSourceTests {

    // MARK: - Helpers

    private func makeSUT() -> (RemoteRunDataSource, RunTestURLProtocol.Type) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RunTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let sut = RemoteRunDataSource(apiClient: apiClient)
        RunTestURLProtocol.reset()
        return (sut, RunTestURLProtocol.self)
    }

    private func makeUploadDTO(
        id: UUID = UUID(),
        distanceKm: Double = 15.5,
        elevationGainM: Double = 450
    ) -> RunUploadRequestDTO {
        let formatter = ISO8601DateFormatter()
        return RunUploadRequestDTO(
            id: id.uuidString,
            date: formatter.string(from: Date()),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 420,
            duration: 5400,
            averageHeartRate: 145,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 348.4,
            gpsTrack: [],
            splits: [],
            notes: "Test run",
            linkedSessionId: nil,
            idempotencyKey: id.uuidString,
            clientUpdatedAt: nil
        )
    }

    private func makeRunResponseJSON(id: UUID = UUID()) -> String {
        """
        {
            "id": "\(id.uuidString)",
            "date": "2026-02-20T08:30:00Z",
            "distance_km": 15.5,
            "elevation_gain_m": 450.0,
            "elevation_loss_m": 420.0,
            "duration": 5400,
            "average_heart_rate": 145,
            "max_heart_rate": 172,
            "average_pace_seconds_per_km": 348.4,
            "gps_track": [],
            "splits": [],
            "notes": "Test run",
            "linked_session_id": null,
            "created_at": "2026-02-20T09:00:00Z",
            "updated_at": null
        }
        """
    }

    private func makePaginatedJSON(runId: UUID = UUID(), hasMore: Bool = false) -> String {
        """
        {
            "items": [{
                "id": "\(runId.uuidString)",
                "date": "2026-02-20T08:30:00Z",
                "distance_km": 15.5,
                "elevation_gain_m": 450.0,
                "elevation_loss_m": 420.0,
                "duration": 5400,
                "average_heart_rate": 145,
                "max_heart_rate": 172,
                "average_pace_seconds_per_km": 348.4,
                "gps_track": [],
                "splits": [],
                "notes": null,
                "linked_session_id": null,
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": null,
            "has_more": \(hasMore)
        }
        """
    }

    // MARK: - uploadRun

    @Test("uploadRun sends POST to /runs and returns response")
    func uploadRunSendsPost() async throws {
        let (sut, proto) = makeSUT()
        let runId = UUID()
        let dto = makeUploadDTO(id: runId)
        proto.responseData = Data(makeRunResponseJSON(id: runId).utf8)
        proto.statusCode = 201

        let response = try await sut.uploadRun(dto)

        #expect(response.id == runId.uuidString)
        #expect(response.distanceKm == 15.5)
        #expect(response.elevationGainM == 450.0)
        #expect(response.duration == 5400)

        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "POST")
        #expect(captured?.url?.path.contains("/runs") == true)
    }

    @Test("uploadRun throws on server error")
    func uploadRunThrowsOnServerError() async throws {
        let (sut, proto) = makeSUT()
        let dto = makeUploadDTO()
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            _ = try await sut.uploadRun(dto)
        }
    }

    // MARK: - updateRun

    @Test("updateRun sends PUT to /runs/{id}")
    func updateRunSendsPut() async throws {
        let (sut, proto) = makeSUT()
        let runId = UUID()
        let dto = makeUploadDTO(id: runId)
        proto.responseData = Data(makeRunResponseJSON(id: runId).utf8)
        proto.statusCode = 200

        let response = try await sut.updateRun(dto, id: runId)

        #expect(response.id == runId.uuidString)
        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "PUT")
        #expect(captured?.url?.path.contains("/runs/\(runId.uuidString)") == true)
    }

    @Test("updateRun throws on 404 client error")
    func updateRunThrowsOnNotFound() async throws {
        let (sut, proto) = makeSUT()
        let dto = makeUploadDTO()
        proto.statusCode = 404
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            _ = try await sut.updateRun(dto, id: UUID())
        }
    }

    // MARK: - deleteRun

    @Test("deleteRun sends DELETE to /runs/{id}")
    func deleteRunSendsDelete() async throws {
        let (sut, proto) = makeSUT()
        let runId = UUID()
        proto.statusCode = 200
        proto.responseData = Data("{}".utf8)

        try await sut.deleteRun(id: runId)

        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "DELETE")
        #expect(captured?.url?.path.contains("/runs/\(runId.uuidString)") == true)
    }

    @Test("deleteRun throws on unauthorized")
    func deleteRunThrowsOnUnauthorized() async throws {
        let (sut, proto) = makeSUT()
        proto.statusCode = 401
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            try await sut.deleteRun(id: UUID())
        }
    }

    // MARK: - fetchRuns

    @Test("fetchRuns sends GET to /runs with pagination")
    func fetchRunsSendsGet() async throws {
        let (sut, proto) = makeSUT()
        let runId = UUID()
        proto.responseData = Data(makePaginatedJSON(runId: runId).utf8)
        proto.statusCode = 200

        let response = try await sut.fetchRuns(limit: 20)

        #expect(response.items.count == 1)
        #expect(response.items[0].id == runId.uuidString)
        #expect(response.hasMore == false)
        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "GET")
        #expect(captured?.url?.path.contains("/runs") == true)
    }

    @Test("fetchRuns includes since parameter in query")
    func fetchRunsIncludesSince() async throws {
        let (sut, proto) = makeSUT()
        proto.responseData = Data(makePaginatedJSON().utf8)
        proto.statusCode = 200

        let since = Date(timeIntervalSince1970: 1_700_000_000)
        _ = try await sut.fetchRuns(since: since, limit: 10)

        let captured = proto.lastRequest
        let query = captured?.url?.query ?? ""
        #expect(query.contains("since="))
        #expect(query.contains("limit=10"))
    }

    @Test("fetchRuns includes cursor parameter")
    func fetchRunsIncludesCursor() async throws {
        let (sut, proto) = makeSUT()
        proto.responseData = Data(makePaginatedJSON().utf8)
        proto.statusCode = 200

        _ = try await sut.fetchRuns(cursor: "abc123", limit: 50)

        let captured = proto.lastRequest
        let query = captured?.url?.query ?? ""
        #expect(query.contains("cursor=abc123"))
        #expect(query.contains("limit=50"))
    }

    @Test("fetchRuns with pagination returns hasMore flag")
    func fetchRunsReturnsHasMoreFlag() async throws {
        let (sut, proto) = makeSUT()
        proto.responseData = Data(makePaginatedJSON(hasMore: true).utf8)
        proto.statusCode = 200

        let response = try await sut.fetchRuns(limit: 20)

        #expect(response.hasMore == true)
    }
}

// MARK: - Stub URL Protocol

private final class RunTestURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func reset() {
        responseData = nil
        statusCode = 200
        lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
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
