@testable import App
import XCTVapor
import Fluent

final class RaceControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validRaceBody(
        raceId: String = UUID().uuidString,
        idempotencyKey: String = UUID().uuidString
    ) -> RaceUploadRequest {
        RaceUploadRequest(
            raceId: raceId,
            name: "UTMB",
            date: "2026-08-28T18:00:00Z",
            distanceKm: 171,
            elevationGainM: 10000,
            priority: "aRace",
            raceJson: "{\"name\":\"UTMB\",\"distance\":171}",
            idempotencyKey: idempotencyKey,
            clientUpdatedAt: nil
        )
    }

    // MARK: - PUT /races (Create)

    func testUpsertRace_create_returnsCreated() async throws {
        let user = try await app.registerUser(email: "race@test.com", password: "password123")

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRaceBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let race = try res.content.decode(RaceResponse.self)
            XCTAssertEqual(race.name, "UTMB")
            XCTAssertEqual(race.distanceKm, 171)
            XCTAssertEqual(race.priority, "aRace")
            XCTAssertFalse(race.id.isEmpty)
        })
    }

    // MARK: - PUT /races (Upsert)

    func testUpsertRace_update_returnsOk() async throws {
        let user = try await app.registerUser(email: "uprace@test.com", password: "password123")
        let raceId = UUID().uuidString

        // Create
        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRaceBody(raceId: raceId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update
        let updated = RaceUploadRequest(
            raceId: raceId,
            name: "CCC",
            date: "2026-08-27T09:00:00Z",
            distanceKm: 101,
            elevationGainM: 6100,
            priority: "bRace",
            raceJson: "{\"name\":\"CCC\",\"distance\":101}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updated)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let race = try res.content.decode(RaceResponse.self)
            XCTAssertEqual(race.name, "CCC")
            XCTAssertEqual(race.distanceKm, 101)
            XCTAssertEqual(race.priority, "bRace")
        })

        // Only one race in DB for this raceId
        let count = try await RaceModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    func testUpsertRace_conflictDetection_returnsConflict() async throws {
        let user = try await app.registerUser(email: "rconflict@test.com", password: "password123")
        let raceId = UUID().uuidString

        // Create
        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRaceBody(raceId: raceId))
        }, afterResponse: { _ in })

        // Update with old clientUpdatedAt
        let conflict = RaceUploadRequest(
            raceId: raceId,
            name: "Conflict Race",
            date: "2026-08-28T18:00:00Z",
            distanceKm: 171,
            elevationGainM: 10000,
            priority: "aRace",
            raceJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: "2020-01-01T00:00:00Z"
        )

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(conflict)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    // MARK: - PUT /races (Validation)

    func testUpsertRace_invalidPriority_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badpri@test.com", password: "password123")

        let body = RaceUploadRequest(
            raceId: UUID().uuidString,
            name: "Test Race",
            date: "2026-08-28T18:00:00Z",
            distanceKm: 50,
            elevationGainM: 3000,
            priority: "dRace", // Invalid priority
            raceJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertRace_invalidDistance_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "baddist@test.com", password: "password123")

        let body = RaceUploadRequest(
            raceId: UUID().uuidString,
            name: "Test Race",
            date: "2026-08-28T18:00:00Z",
            distanceKm: 0, // Below 0.1 min
            elevationGainM: 3000,
            priority: "aRace",
            raceJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertRace_invalidDate_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "baddate@test.com", password: "password123")

        let body = RaceUploadRequest(
            raceId: UUID().uuidString,
            name: "Test Race",
            date: "not-a-date",
            distanceKm: 50,
            elevationGainM: 3000,
            priority: "aRace",
            raceJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertRace_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            try req.content.encode(validRaceBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /races

    func testListRaces_empty_returnsEmptyPage() async throws {
        let user = try await app.registerUser(email: "noraces@test.com", password: "password123")

        try await app.test(.GET, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let page = try res.content.decode(PaginatedResponse<RaceResponse>.self)
            XCTAssertTrue(page.items.isEmpty)
            XCTAssertFalse(page.hasMore)
        })
    }

    func testListRaces_returnsUserRaces() async throws {
        let user = try await app.registerUser(email: "listraces@test.com", password: "password123")

        for i in 0..<3 {
            let body = RaceUploadRequest(
                raceId: "race-\(i)",
                name: "Race \(i)",
                date: "2026-0\(i + 1)-15T09:00:00Z",
                distanceKm: Double(50 + i * 20),
                elevationGainM: Double(2000 + i * 1000),
                priority: i == 0 ? "aRace" : "bRace",
                raceJson: "{}",
                idempotencyKey: UUID().uuidString,
                clientUpdatedAt: nil
            )
            try await app.test(.PUT, "v1/races", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(body)
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let page = try res.content.decode(PaginatedResponse<RaceResponse>.self)
            XCTAssertEqual(page.items.count, 3)
        })
    }

    func testListRaces_pagination_respectsLimit() async throws {
        let user = try await app.registerUser(email: "pagerace@test.com", password: "password123")

        for i in 0..<3 {
            let body = RaceUploadRequest(
                raceId: "pr-\(i)",
                name: "Race \(i)",
                date: "2026-0\(i + 1)-15T09:00:00Z",
                distanceKm: 50,
                elevationGainM: 3000,
                priority: "aRace",
                raceJson: "{}",
                idempotencyKey: UUID().uuidString,
                clientUpdatedAt: nil
            )
            try await app.test(.PUT, "v1/races", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(body)
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/races?limit=2", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            let page = try res.content.decode(PaginatedResponse<RaceResponse>.self)
            XCTAssertEqual(page.items.count, 2)
            XCTAssertTrue(page.hasMore)
            XCTAssertNotNil(page.nextCursor)
        })
    }

    // MARK: - DELETE /races/:raceId

    func testDeleteRace_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "delrace@test.com", password: "password123")
        let raceId = "my-race-id"

        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRaceBody(raceId: raceId))
        }, afterResponse: { _ in })

        try await app.test(.DELETE, "v1/races/\(raceId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        let count = try await RaceModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteRace_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "delnfrace@test.com", password: "password123")

        try await app.test(.DELETE, "v1/races/nonexistent", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteRace_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/races/some-id", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testRace_usersCannotAccessOtherRaces() async throws {
        let user1 = try await app.registerUser(email: "riso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "riso2@test.com", password: "password123")
        let raceId = "isolated-race"

        // User1 creates a race
        try await app.test(.PUT, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validRaceBody(raceId: raceId))
        }, afterResponse: { _ in })

        // User2 list should be empty
        try await app.test(.GET, "v1/races", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let page = try res.content.decode(PaginatedResponse<RaceResponse>.self)
            XCTAssertTrue(page.items.isEmpty)
        })

        // User2 cannot delete it
        try await app.test(.DELETE, "v1/races/\(raceId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
