import Foundation
import Testing
@testable import UltraTrain

@Suite("FitnessSyncService Tests", .serialized)
struct FitnessSyncServiceTests {

    // MARK: - Helpers

    private func makeSUT(
        authenticated: Bool = true
    ) -> (FitnessSyncService, MockAuthService, FitnessSyncTestURLProtocol.Type) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FitnessSyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: URL(string: "https://api.ultratrain.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
        let remote = RemoteFitnessDataSource(apiClient: apiClient)
        FitnessSyncTestURLProtocol.reset()

        let sut = FitnessSyncService(remote: remote, authService: auth)
        return (sut, auth, FitnessSyncTestURLProtocol.self)
    }

    private func makeSnapshot(
        id: UUID = UUID(),
        fitness: Double = 45.0,
        fatigue: Double = 30.0,
        form: Double = 15.0
    ) -> FitnessSnapshot {
        FitnessSnapshot(
            id: id,
            date: Date(),
            fitness: fitness,
            fatigue: fatigue,
            form: form,
            weeklyVolumeKm: 65.0,
            weeklyElevationGainM: 2500.0,
            weeklyDuration: 28800,
            acuteToChronicRatio: 1.1,
            monotony: 1.3
        )
    }

    private func makeSnapshotResponseJSON(snapshot: FitnessSnapshot) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(snapshot)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let formatter = ISO8601DateFormatter()

        return """
        {
            "id": "\(UUID().uuidString)",
            "snapshot_id": "\(snapshot.id.uuidString)",
            "date": "\(formatter.string(from: snapshot.date))",
            "fitness": \(snapshot.fitness),
            "fatigue": \(snapshot.fatigue),
            "form": \(snapshot.form),
            "fitness_json": "\(escaped)",
            "created_at": null,
            "updated_at": null
        }
        """
    }

    private func makePaginatedResponseJSON(snapshot: FitnessSnapshot) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(snapshot)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let escaped = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let formatter = ISO8601DateFormatter()

        return """
        {
            "items": [{
                "id": "\(UUID().uuidString)",
                "snapshot_id": "\(snapshot.id.uuidString)",
                "date": "\(formatter.string(from: snapshot.date))",
                "fitness": \(snapshot.fitness),
                "fatigue": \(snapshot.fatigue),
                "form": \(snapshot.form),
                "fitness_json": "\(escaped)",
                "created_at": null,
                "updated_at": null
            }],
            "next_cursor": null,
            "has_more": false
        }
        """
    }

    // MARK: - syncSnapshot

    @Test("syncSnapshot uploads when authenticated")
    func syncUploadsWhenAuthenticated() async {
        let snapshot = makeSnapshot()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makeSnapshotResponseJSON(snapshot: snapshot).utf8)
        proto.statusCode = 200

        await sut.syncSnapshot(snapshot)

        #expect(proto.requestCount > 0)
    }

    @Test("syncSnapshot skips when not authenticated")
    func syncSkipsWhenNotAuthenticated() async {
        let snapshot = makeSnapshot()
        let (sut, _, proto) = makeSUT(authenticated: false)

        await sut.syncSnapshot(snapshot)

        #expect(proto.requestCount == 0)
    }

    @Test("syncSnapshot handles remote error gracefully")
    func syncHandlesError() async {
        let snapshot = makeSnapshot()
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        await sut.syncSnapshot(snapshot)

        #expect(proto.requestCount > 0)
    }

    // MARK: - restoreSnapshots

    @Test("restoreSnapshots returns empty when not authenticated")
    func restoreEmptyWhenNotAuthenticated() async {
        let (sut, _, proto) = makeSUT(authenticated: false)

        let snapshots = await sut.restoreSnapshots()

        #expect(snapshots.isEmpty)
        #expect(proto.requestCount == 0)
    }

    @Test("restoreSnapshots returns empty on server error")
    func restoreEmptyOnError() async {
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.statusCode = 500
        proto.responseData = Data("{}".utf8)

        let snapshots = await sut.restoreSnapshots()

        #expect(snapshots.isEmpty)
    }

    @Test("restoreSnapshots returns decoded snapshots from server")
    func restoreReturnsSnapshots() async {
        let snapshot = makeSnapshot(fitness: 50.0, fatigue: 25.0, form: 25.0)
        let (sut, _, proto) = makeSUT(authenticated: true)
        proto.responseData = Data(makePaginatedResponseJSON(snapshot: snapshot).utf8)
        proto.statusCode = 200

        let snapshots = await sut.restoreSnapshots()

        #expect(snapshots.count == 1)
        #expect(snapshots.first?.id == snapshot.id)
        #expect(snapshots.first?.fitness == 50.0)
        #expect(snapshots.first?.form == 25.0)
    }
}

// MARK: - Stub URL Protocol

private final class FitnessSyncTestURLProtocol: URLProtocol, @unchecked Sendable {
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
