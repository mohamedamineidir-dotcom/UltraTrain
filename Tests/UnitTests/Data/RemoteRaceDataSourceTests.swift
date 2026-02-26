import Foundation
import Testing
@testable import UltraTrain

@Suite("RemoteRaceDataSource Tests", .serialized)
struct RemoteRaceDataSourceTests {

    // MARK: - Helpers

    private func makeSUT() -> (RemoteRaceDataSource, RaceTestURLProtocol.Type) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RaceTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let sut = RemoteRaceDataSource(apiClient: apiClient)
        RaceTestURLProtocol.reset()
        return (sut, RaceTestURLProtocol.self)
    }

    private func makeUploadDTO(
        raceId: UUID = UUID(),
        name: String = "UTMB"
    ) -> RaceUploadRequestDTO {
        let formatter = ISO8601DateFormatter()
        return RaceUploadRequestDTO(
            raceId: raceId.uuidString,
            name: name,
            date: formatter.string(from: Date()),
            distanceKm: 171,
            elevationGainM: 10000,
            priority: "aRace",
            raceJson: "{\"name\":\"\(name)\"}",
            idempotencyKey: raceId.uuidString,
            clientUpdatedAt: nil
        )
    }

    private func makeRaceResponseJSON(
        id: String = UUID().uuidString,
        raceId: UUID = UUID(),
        name: String = "UTMB"
    ) -> String {
        """
        {
            "id": "\(id)",
            "race_id": "\(raceId.uuidString)",
            "name": "\(name)",
            "date": "2026-08-28T06:00:00Z",
            "distance_km": 171.0,
            "elevation_gain_m": 10000.0,
            "priority": "aRace",
            "race_json": "{\\"name\\":\\"\(name)\\"}",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    private func makePaginatedRaceJSON(
        raceId: UUID = UUID(),
        hasMore: Bool = false,
        nextCursor: String? = nil
    ) -> String {
        let cursorValue = nextCursor.map { "\"\($0)\"" } ?? "null"
        return """
        {
            "items": [{
                "id": "\(UUID().uuidString)",
                "race_id": "\(raceId.uuidString)",
                "name": "UTMB",
                "date": "2026-08-28T06:00:00Z",
                "distance_km": 171.0,
                "elevation_gain_m": 10000.0,
                "priority": "aRace",
                "race_json": "{\\"name\\":\\"UTMB\\"}",
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": \(cursorValue),
            "has_more": \(hasMore)
        }
        """
    }

    // MARK: - upsertRace

    @Test("upsertRace sends PUT to /races and returns response")
    func upsertRaceSendsPut() async throws {
        let (sut, proto) = makeSUT()
        let raceId = UUID()
        let dto = makeUploadDTO(raceId: raceId)
        proto.responseData = Data(makeRaceResponseJSON(raceId: raceId).utf8)
        proto.statusCode = 200

        let response = try await sut.upsertRace(dto)

        #expect(response.raceId == raceId.uuidString)
        #expect(response.name == "UTMB")
        #expect(response.distanceKm == 171.0)
        #expect(response.elevationGainM == 10000.0)
        #expect(response.priority == "aRace")

        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "PUT")
        #expect(captured?.url?.path.contains("/races") == true)
    }

    @Test("upsertRace throws on server error")
    func upsertRaceThrowsOnServerError() async throws {
        let (sut, proto) = makeSUT()
        let dto = makeUploadDTO()
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            _ = try await sut.upsertRace(dto)
        }
    }

    @Test("upsertRace throws on conflict")
    func upsertRaceThrowsOnConflict() async throws {
        let (sut, proto) = makeSUT()
        let dto = makeUploadDTO()
        proto.statusCode = 409
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            _ = try await sut.upsertRace(dto)
        }
    }

    @Test("upsertRace sends request body with correct content type")
    func upsertRaceSendsCorrectContentType() async throws {
        let (sut, proto) = makeSUT()
        let dto = makeUploadDTO()
        proto.responseData = Data(makeRaceResponseJSON().utf8)
        proto.statusCode = 200

        _ = try await sut.upsertRace(dto)

        let captured = proto.lastRequest
        #expect(captured?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(captured?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    // MARK: - fetchRaces

    @Test("fetchRaces sends GET to /races with pagination")
    func fetchRacesSendsGet() async throws {
        let (sut, proto) = makeSUT()
        let raceId = UUID()
        proto.responseData = Data(makePaginatedRaceJSON(raceId: raceId).utf8)
        proto.statusCode = 200

        let response = try await sut.fetchRaces(limit: 20)

        #expect(response.items.count == 1)
        #expect(response.items[0].raceId == raceId.uuidString)
        #expect(response.items[0].name == "UTMB")
        #expect(response.hasMore == false)
        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "GET")
    }

    @Test("fetchRaces includes cursor in query parameters")
    func fetchRacesIncludesCursor() async throws {
        let (sut, proto) = makeSUT()
        proto.responseData = Data(makePaginatedRaceJSON().utf8)
        proto.statusCode = 200

        _ = try await sut.fetchRaces(cursor: "page2cursor", limit: 50)

        let captured = proto.lastRequest
        let query = captured?.url?.query ?? ""
        #expect(query.contains("cursor=page2cursor"))
        #expect(query.contains("limit=50"))
    }

    @Test("fetchRaces returns hasMore and nextCursor")
    func fetchRacesReturnsPaginationFields() async throws {
        let (sut, proto) = makeSUT()
        proto.responseData = Data(makePaginatedRaceJSON(hasMore: true, nextCursor: "next123").utf8)
        proto.statusCode = 200

        let response = try await sut.fetchRaces(limit: 20)

        #expect(response.hasMore == true)
        #expect(response.nextCursor == "next123")
    }

    @Test("fetchRaces throws on server error")
    func fetchRacesThrowsOnServerError() async throws {
        let (sut, proto) = makeSUT()
        proto.statusCode = 503
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            _ = try await sut.fetchRaces()
        }
    }

    // MARK: - deleteRace

    @Test("deleteRace sends DELETE to /races/{id}")
    func deleteRaceSendsDelete() async throws {
        let (sut, proto) = makeSUT()
        let raceId = UUID()
        proto.statusCode = 200
        proto.responseData = Data("{}".utf8)

        try await sut.deleteRace(id: raceId.uuidString)

        let captured = proto.lastRequest
        #expect(captured?.httpMethod == "DELETE")
        #expect(captured?.url?.path.contains("/races/\(raceId.uuidString)") == true)
    }

    @Test("deleteRace throws on unauthorized")
    func deleteRaceThrowsOnUnauthorized() async throws {
        let (sut, proto) = makeSUT()
        proto.statusCode = 401
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            try await sut.deleteRace(id: UUID().uuidString)
        }
    }

    @Test("deleteRace throws on not found")
    func deleteRaceThrowsOnNotFound() async throws {
        let (sut, proto) = makeSUT()
        proto.statusCode = 404
        proto.responseData = Data("{}".utf8)

        await #expect(throws: APIError.self) {
            try await sut.deleteRace(id: UUID().uuidString)
        }
    }
}

// MARK: - Stub URL Protocol

private final class RaceTestURLProtocol: URLProtocol, @unchecked Sendable {
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
