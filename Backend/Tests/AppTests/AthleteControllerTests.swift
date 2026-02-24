@testable import App
import XCTVapor
import Fluent

final class AthleteControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validAthleteBody() -> AthleteUpdateRequest {
        AthleteUpdateRequest(
            firstName: "Kilian",
            lastName: "Jornet",
            dateOfBirth: "1987-10-27T00:00:00Z",
            weightKg: 62.0,
            heightCm: 171.0,
            restingHeartRate: 42,
            maxHeartRate: 195,
            experienceLevel: "elite",
            weeklyVolumeKm: 150.0,
            longestRunKm: 170.0
        )
    }

    // MARK: - GET /athlete

    func testGetAthlete_noProfile_returnsNotFound() async throws {
        let user = try await app.registerUser(email: "noathlete@test.com", password: "password123")

        try await app.test(.GET, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testGetAthlete_withProfile_returnsAthlete() async throws {
        let user = try await app.registerUser(email: "getathlete@test.com", password: "password123")

        // Create profile first
        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validAthleteBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Now GET
        try await app.test(.GET, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let athlete = try res.content.decode(AthleteResponse.self)
            XCTAssertEqual(athlete.firstName, "Kilian")
            XCTAssertEqual(athlete.lastName, "Jornet")
            XCTAssertEqual(athlete.weightKg, 62.0)
            XCTAssertEqual(athlete.heightCm, 171.0)
            XCTAssertEqual(athlete.restingHeartRate, 42)
            XCTAssertEqual(athlete.maxHeartRate, 195)
            XCTAssertEqual(athlete.experienceLevel, "elite")
        })
    }

    func testGetAthlete_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/athlete", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - PUT /athlete (Create)

    func testUpdateAthlete_create_returnsAthlete() async throws {
        let user = try await app.registerUser(email: "create@test.com", password: "password123")

        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validAthleteBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let athlete = try res.content.decode(AthleteResponse.self)
            XCTAssertEqual(athlete.firstName, "Kilian")
            XCTAssertEqual(athlete.lastName, "Jornet")
            XCTAssertFalse(athlete.id.isEmpty)
        })
    }

    // MARK: - PUT /athlete (Upsert)

    func testUpdateAthlete_upsert_updatesExisting() async throws {
        let user = try await app.registerUser(email: "upsert@test.com", password: "password123")

        // Create
        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validAthleteBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Update
        let updated = AthleteUpdateRequest(
            firstName: "Jim",
            lastName: "Walmsley",
            dateOfBirth: "1990-01-15T00:00:00Z",
            weightKg: 70.0,
            heightCm: 183.0,
            restingHeartRate: 45,
            maxHeartRate: 190,
            experienceLevel: "advanced",
            weeklyVolumeKm: 200.0,
            longestRunKm: 160.0
        )

        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updated)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let athlete = try res.content.decode(AthleteResponse.self)
            XCTAssertEqual(athlete.firstName, "Jim")
            XCTAssertEqual(athlete.lastName, "Walmsley")
            XCTAssertEqual(athlete.weightKg, 70.0)
        })

        // Only one athlete record should exist
        let count = try await AthleteModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    // MARK: - PUT /athlete (Validation)

    func testUpdateAthlete_invalidWeight_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badweight@test.com", password: "password123")

        let body = AthleteUpdateRequest(
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: "1990-01-01T00:00:00Z",
            weightKg: 5.0,  // Below 20 min
            heightCm: 170.0,
            restingHeartRate: 60,
            maxHeartRate: 180,
            experienceLevel: "beginner",
            weeklyVolumeKm: 30.0,
            longestRunKm: 15.0
        )

        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateAthlete_invalidHeartRate_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badhr@test.com", password: "password123")

        let body = AthleteUpdateRequest(
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: "1990-01-01T00:00:00Z",
            weightKg: 70.0,
            heightCm: 170.0,
            restingHeartRate: 10,  // Below 30 min
            maxHeartRate: 180,
            experienceLevel: "beginner",
            weeklyVolumeKm: 30.0,
            longestRunKm: 15.0
        )

        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateAthlete_invalidDateFormat_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "baddate@test.com", password: "password123")

        let body = AthleteUpdateRequest(
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: "not-a-date",
            weightKg: 70.0,
            heightCm: 170.0,
            restingHeartRate: 60,
            maxHeartRate: 180,
            experienceLevel: "beginner",
            weeklyVolumeKm: 30.0,
            longestRunKm: 15.0
        )

        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateAthlete_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            try req.content.encode(validAthleteBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testAthlete_usersCannotSeeOtherProfiles() async throws {
        let user1 = try await app.registerUser(email: "user1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "user2@test.com", password: "password123")

        // User1 creates profile
        try await app.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validAthleteBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // User2 should not see it
        try await app.test(.GET, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
