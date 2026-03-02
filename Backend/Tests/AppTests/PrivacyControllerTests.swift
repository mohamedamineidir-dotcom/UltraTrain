@testable import App
import XCTVapor

final class PrivacyControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - GET /privacy

    func testPrivacy_returnsOkWithHTML() async throws {
        try await app.test(.GET, "privacy", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let body = res.body.string
            XCTAssertTrue(body.contains("Privacy Policy"))
            XCTAssertTrue(body.contains("<!DOCTYPE html>"))
        })
    }

    func testPrivacy_contentTypeIsHTML() async throws {
        try await app.test(.GET, "privacy", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let contentType = res.headers.first(name: .contentType)
            XCTAssertTrue(contentType?.contains("text/html") ?? false)
        })
    }

    func testPrivacy_containsRequiredSections() async throws {
        try await app.test(.GET, "privacy", afterResponse: { res in
            let body = res.body.string
            XCTAssertTrue(body.contains("Data We Collect"))
            XCTAssertTrue(body.contains("Apple HealthKit"))
            XCTAssertTrue(body.contains("Data Storage"))
            XCTAssertTrue(body.contains("Your Rights"))
        })
    }

    func testPrivacy_noAuthRequired() async throws {
        // Privacy page should be accessible without authentication
        try await app.test(.GET, "privacy", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    // MARK: - GET /terms

    func testTerms_returnsOkWithHTML() async throws {
        try await app.test(.GET, "terms", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let body = res.body.string
            XCTAssertTrue(body.contains("Terms of Service"))
            XCTAssertTrue(body.contains("<!DOCTYPE html>"))
        })
    }

    func testTerms_contentTypeIsHTML() async throws {
        try await app.test(.GET, "terms", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let contentType = res.headers.first(name: .contentType)
            XCTAssertTrue(contentType?.contains("text/html") ?? false)
        })
    }

    func testTerms_containsRequiredSections() async throws {
        try await app.test(.GET, "terms", afterResponse: { res in
            let body = res.body.string
            XCTAssertTrue(body.contains("Acceptance"))
            XCTAssertTrue(body.contains("Health Disclaimer"))
            XCTAssertTrue(body.contains("User Responsibilities"))
            XCTAssertTrue(body.contains("Termination"))
        })
    }

    func testTerms_noAuthRequired() async throws {
        try await app.test(.GET, "terms", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
}
