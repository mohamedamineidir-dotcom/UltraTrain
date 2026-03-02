import Foundation
import Testing
@testable import UltraTrain

@Suite("OSMTrailService Tests")
struct OSMTrailServiceTests {

    // NOTE: OSMTrailService makes HTTP requests to the Overpass API.
    // We test the parsing and distance computation logic using a mock URLSession
    // via URLProtocol, and verify error handling for non-200 responses.

    // MARK: - Response Parsing

    @Test("parseResponse extracts trail results from valid JSON")
    func parseValidJSON() async throws {
        let json: [String: Any] = [
            "elements": [
                [
                    "id": 12345,
                    "type": "way",
                    "tags": ["name": "Sentier du Mont Blanc"],
                    "geometry": [
                        ["lat": 45.832, "lon": 6.865],
                        ["lat": 45.833, "lon": 6.866],
                        ["lat": 45.834, "lon": 6.867]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        let results = try await service.searchTrails(
            near: .init(latitude: 45.83, longitude: 6.86),
            radiusKm: 5
        )

        #expect(!results.isEmpty)
        #expect(results.first?.name == "Sentier du Mont Blanc")
        #expect(results.first?.trackPoints.count == 3)
    }

    @Test("parseResponse returns empty for elements with fewer than 2 geometry points")
    func parseSkipsShortGeometry() async throws {
        let json: [String: Any] = [
            "elements": [
                [
                    "id": 999,
                    "type": "way",
                    "tags": [:] as [String: String],
                    "geometry": [
                        ["lat": 45.0, "lon": 6.0]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        let results = try await service.searchTrails(
            near: .init(latitude: 45.0, longitude: 6.0)
        )
        #expect(results.isEmpty)
    }

    @Test("parseResponse assigns 'Unnamed Trail' when name tag is missing")
    func parseUnnamedTrail() async throws {
        let json: [String: Any] = [
            "elements": [
                [
                    "id": 555,
                    "type": "way",
                    "tags": [:] as [String: String],
                    "geometry": [
                        ["lat": 45.0, "lon": 6.0],
                        ["lat": 45.01, "lon": 6.01]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        let results = try await service.searchTrails(
            near: .init(latitude: 45.0, longitude: 6.0)
        )
        #expect(results.first?.name == "Unnamed Trail")
    }

    // MARK: - Error Handling

    @Test("searchTrails throws networkUnavailable for non-200 response")
    func throwsOnNon200Response() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        do {
            _ = try await service.searchTrails(
                near: .init(latitude: 45.0, longitude: 6.0)
            )
            Issue.record("Expected DomainError.networkUnavailable")
        } catch {
            #expect(error as? DomainError == .networkUnavailable)
        }
    }

    @Test("results are sorted by distance descending")
    func resultsSortedByDistanceDescending() async throws {
        let json: [String: Any] = [
            "elements": [
                [
                    "id": 1,
                    "type": "way",
                    "tags": ["name": "Short"],
                    "geometry": [
                        ["lat": 45.0, "lon": 6.0],
                        ["lat": 45.001, "lon": 6.001]
                    ]
                ],
                [
                    "id": 2,
                    "type": "way",
                    "tags": ["name": "Long"],
                    "geometry": [
                        ["lat": 45.0, "lon": 6.0],
                        ["lat": 45.01, "lon": 6.01],
                        ["lat": 45.02, "lon": 6.02]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        let results = try await service.searchTrails(
            near: .init(latitude: 45.0, longitude: 6.0)
        )

        #expect(results.count == 2)
        if results.count == 2 {
            #expect(results[0].distanceKm >= results[1].distanceKm)
        }
    }

    // MARK: - Search By Name

    @Test("searchTrails by name sends correct query")
    func searchByNameSendsQuery() async throws {
        let json: [String: Any] = ["elements": [] as [[String: Any]]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        var capturedBody: String?
        MockURLProtocol.requestHandler = { request in
            // httpBody is nil in URLProtocol; read from httpBodyStream instead
            if let stream = request.httpBodyStream {
                stream.open()
                var bodyData = Data()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: 1024)
                    if read > 0 { bodyData.append(buffer, count: read) }
                    else { break }
                }
                stream.close()
                capturedBody = String(data: bodyData, encoding: .utf8)
            } else if let body = request.httpBody {
                capturedBody = String(data: body, encoding: .utf8)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let session = URLSession(configuration: config)
        let service = OSMTrailService(session: session)

        _ = try await service.searchTrails(byName: "Grand Balcon")

        #expect(capturedBody?.contains("Grand") == true)
    }
}

// MARK: - MockURLProtocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
