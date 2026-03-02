import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceSyncService Tests", .serialized)
struct RaceSyncServiceTests {

    // MARK: - Helpers

    private func makeSUT(
        authenticated: Bool = true
    ) -> (RaceSyncService, MockAuthService, RaceSyncTestURLProtocol.Type) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RaceSyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let remote = RemoteRaceDataSource(apiClient: apiClient)
        RaceSyncTestURLProtocol.reset()

        let sut = RaceSyncService(remote: remote, authService: auth)
        return (sut, auth, RaceSyncTestURLProtocol.self)
    }

    private func makeRace(
        id: UUID = UUID(),
        name: String = "UTMB",
        distanceKm: Double = 171.0,
        elevationGainM: Double = 10000.0
    ) -> Race {
        Race(
            id: id,
            name: name,
            date: Date().addingTimeInterval(86400 * 90),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 10000.0,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical
        )
    }

    private func makeRaceResponseJSON(race: Race) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(race)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let formatter = ISO8601DateFormatter()

        return """
        {
            "id": "\(UUID().uuidString)",
            "race_id": "\(race.id.uuidString)",
            "name": "\(race.name)",
            "date": "\(formatter.string(from: race.date))",
            "distance_km": \(race.distanceKm),
            "elevation_gain_m": \(race.elevationGainM),
            "priority": "\(race.priority.rawValue)",
            "race_json": "\(escaped)",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    private func makePaginatedResponseJSON(race: Race) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(race)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let formatter = ISO8601DateFormatter()

        return """
        {
            "items": [{
                "id": "\(UUID().uuidString)",
                "race_id": "\(race.id.uuidString)",
                "name": "\(race.name)",
                "date": "\(formatter.string(from: race.date))",
                "distance_km": \(race.distanceKm),
                "elevation_gain_m": \(race.elevationGainM),
                "priority": "\(race.priority.rawValue)",
                "race_json": "\(escaped)",
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": null,
            "has_more": false
        }
        """
    }

    // MARK: - syncRace

    @Test("syncRace uploads race when authenticated")
    func syncUploadsWhenAuthenticated() async {
        let race = makeRace()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makeRaceResponseJSON(race: race).utf8)
        proto.statusCode = 200

        await sut.syncRace(race)

        #expect(proto.requestCount > 0)
    }

    @Test("syncRace skips when not authenticated")
    func syncSkipsWhenNotAuthenticated() async {
        let race = makeRace()
        let (sut, _, proto) = makeSUT(authenticated: false)

        await sut.syncRace(race)

        #expect(proto.requestCount == 0)
    }

    @Test("syncRace handles server error gracefully")
    func syncHandlesError() async {
        let race = makeRace()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await sut.syncRace(race)

        #expect(proto.requestCount > 0)
    }

    // MARK: - deleteRace

    @Test("deleteRace sends request when authenticated")
    func deleteWhenAuthenticated() async {
        let raceId = UUID()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 200
        proto.responseData = Data("{}".utf8)

        await sut.deleteRace(id: raceId)

        #expect(proto.requestCount > 0)
        #expect(proto.lastRequest?.httpMethod == "DELETE")
    }

    @Test("deleteRace skips when not authenticated")
    func deleteSkipsWhenNotAuthenticated() async {
        let raceId = UUID()
        let (sut, _, proto) = makeSUT(authenticated: false)

        await sut.deleteRace(id: raceId)

        #expect(proto.requestCount == 0)
    }

    @Test("deleteRace handles server error gracefully")
    func deleteHandlesError() async {
        let raceId = UUID()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await sut.deleteRace(id: raceId)

        #expect(proto.requestCount > 0)
    }

    // MARK: - restoreRaces

    @Test("restoreRaces returns empty when not authenticated")
    func restoreEmptyWhenNotAuthenticated() async {
        let (sut, _, proto) = makeSUT(authenticated: false)

        let races = await sut.restoreRaces()

        #expect(races.isEmpty)
        #expect(proto.requestCount == 0)
    }

    @Test("restoreRaces returns empty on server error")
    func restoreEmptyOnError() async {
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        let races = await sut.restoreRaces()

        #expect(races.isEmpty)
    }

    @Test("restoreRaces returns decoded races from server")
    func restoreReturnsRaces() async {
        let race = makeRace(name: "CCC", distanceKm: 101.0, elevationGainM: 6100.0)
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makePaginatedResponseJSON(race: race).utf8)
        proto.statusCode = 200

        let races = await sut.restoreRaces()

        #expect(races.count == 1)
        #expect(races.first?.id == race.id)
        #expect(races.first?.name == "CCC")
        #expect(races.first?.distanceKm == 101.0)
    }
}

// MARK: - Stub URL Protocol

private final class RaceSyncTestURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var requestCount: Int = 0
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func reset() {
        responseData = nil
        statusCode = 200
        requestCount = 0
        lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
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
