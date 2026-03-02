@testable import App
import XCTVapor
import Fluent

final class FitnessControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validSnapshotBody(
        snapshotId: String = UUID().uuidString,
        date: String = "2026-03-01T00:00:00Z",
        idempotencyKey: String = UUID().uuidString
    ) -> FitnessSnapshotUpsertRequest {
        FitnessSnapshotUpsertRequest(
            snapshotId: snapshotId,
            date: date,
            fitness: 42.5,
            fatigue: 30.0,
            form: 12.5,
            fitnessJson: "{\"ctl\":42.5,\"atl\":30.0,\"tsb\":12.5}",
            idempotencyKey: idempotencyKey,
            clientUpdatedAt: nil
        )
    }

    // MARK: - PUT /fitness-snapshots (Create)

    func testUpsertSnapshot_create_returnsCreated() async throws {
        let user = try await app.registerUser(email: "fitcreate@test.com", password: "password123")

        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validSnapshotBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let snapshot = try res.content.decode(FitnessSnapshotResponse.self)
            XCTAssertEqual(snapshot.fitness, 42.5)
            XCTAssertEqual(snapshot.fatigue, 30.0)
            XCTAssertEqual(snapshot.form, 12.5)
            XCTAssertFalse(snapshot.id.isEmpty)
            XCTAssertFalse(snapshot.snapshotId.isEmpty)
        })
    }

    func testUpsertSnapshot_update_returnsOk() async throws {
        let user = try await app.registerUser(email: "fitupdate@test.com", password: "password123")
        let snapId = UUID().uuidString

        // Create
        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validSnapshotBody(snapshotId: snapId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update same snapshotId
        let updatedBody = FitnessSnapshotUpsertRequest(
            snapshotId: snapId,
            date: "2026-03-02T00:00:00Z",
            fitness: 50.0,
            fatigue: 35.0,
            form: 15.0,
            fitnessJson: "{\"ctl\":50.0,\"atl\":35.0,\"tsb\":15.0}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updatedBody)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let snapshot = try res.content.decode(FitnessSnapshotResponse.self)
            XCTAssertEqual(snapshot.fitness, 50.0)
            XCTAssertEqual(snapshot.snapshotId, snapId)
        })
    }

    func testUpsertSnapshot_invalidDate_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "fitbaddate@test.com", password: "password123")

        let body = FitnessSnapshotUpsertRequest(
            snapshotId: UUID().uuidString,
            date: "not-a-date",
            fitness: 42.5,
            fatigue: 30.0,
            form: 12.5,
            fitnessJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertSnapshot_emptySnapshotId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "fitemptyid@test.com", password: "password123")

        let body = FitnessSnapshotUpsertRequest(
            snapshotId: "",
            date: "2026-03-01T00:00:00Z",
            fitness: 42.5,
            fatigue: 30.0,
            form: 12.5,
            fitnessJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertSnapshot_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            try req.content.encode(self.validSnapshotBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /fitness-snapshots (List)

    func testListSnapshots_empty_returnsEmptyItems() async throws {
        let user = try await app.registerUser(email: "fitlist@test.com", password: "password123")

        try await app.test(.GET, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<FitnessSnapshotResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
            XCTAssertFalse(paginated.hasMore)
        })
    }

    func testListSnapshots_withItems_returnsAll() async throws {
        let user = try await app.registerUser(email: "fitlistall@test.com", password: "password123")

        // Create three snapshots
        for i in 0..<3 {
            try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(self.validSnapshotBody(date: "2026-03-0\(i + 1)T00:00:00Z"))
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<FitnessSnapshotResponse>.self)
            XCTAssertEqual(paginated.items.count, 3)
        })
    }

    func testListSnapshots_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/fitness-snapshots", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - DELETE /fitness-snapshots/:snapshotId

    func testDeleteSnapshot_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "fitdel@test.com", password: "password123")

        var snapshotServerId: String?
        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validSnapshotBody())
        }, afterResponse: { res in
            snapshotServerId = try res.content.decode(FitnessSnapshotResponse.self).id
        })

        try await app.test(.DELETE, "v1/fitness-snapshots/\(snapshotServerId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        let count = try await FitnessSnapshotModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteSnapshot_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "fitdelnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/fitness-snapshots/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteSnapshot_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "fitdelbad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/fitness-snapshots/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testDeleteSnapshot_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/fitness-snapshots/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testSnapshot_userIsolation_cannotSeeOtherUsersSnapshots() async throws {
        let user1 = try await app.registerUser(email: "fitiso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "fitiso2@test.com", password: "password123")

        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validSnapshotBody())
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let paginated = try res.content.decode(PaginatedResponse<FitnessSnapshotResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
        })
    }

    func testSnapshot_userIsolation_cannotDeleteOtherUsersSnapshot() async throws {
        let user1 = try await app.registerUser(email: "fitisodel1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "fitisodel2@test.com", password: "password123")

        var snapshotServerId: String?
        try await app.test(.PUT, "v1/fitness-snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validSnapshotBody())
        }, afterResponse: { res in
            snapshotServerId = try res.content.decode(FitnessSnapshotResponse.self).id
        })

        try await app.test(.DELETE, "v1/fitness-snapshots/\(snapshotServerId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
