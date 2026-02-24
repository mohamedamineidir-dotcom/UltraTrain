@testable import App
import XCTVapor
import Fluent

final class RunControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validRunBody(
        id: String = UUID().uuidString,
        idempotencyKey: String = UUID().uuidString
    ) -> RunUploadRequest {
        RunUploadRequest(
            id: id,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 42.2,
            elevationGainM: 2500,
            elevationLossM: 2500,
            duration: 18000,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 426,
            gpsTrack: [
                TrackPointServerDTO(latitude: 45.8, longitude: 6.86, altitudeM: 1200, timestamp: "2026-02-20T08:30:00Z", heartRate: 140),
                TrackPointServerDTO(latitude: 45.81, longitude: 6.87, altitudeM: 1250, timestamp: "2026-02-20T08:35:00Z", heartRate: 155)
            ],
            splits: [
                SplitServerDTO(id: UUID().uuidString, kilometerNumber: 1, duration: 420, elevationChangeM: 50, averageHeartRate: 145)
            ],
            notes: "UTMB training run",
            linkedSessionId: nil,
            idempotencyKey: idempotencyKey,
            clientUpdatedAt: nil
        )
    }

    // MARK: - POST /runs

    func testUploadRun_valid_returnsCreated() async throws {
        let user = try await app.registerUser(email: "run@test.com", password: "password123")

        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let run = try res.content.decode(RunResponse.self)
            XCTAssertEqual(run.distanceKm, 42.2)
            XCTAssertEqual(run.elevationGainM, 2500)
            XCTAssertEqual(run.duration, 18000)
            XCTAssertFalse(run.id.isEmpty)
        })
    }

    func testUploadRun_idempotent_returnsSameRun() async throws {
        let user = try await app.registerUser(email: "idem@test.com", password: "password123")
        let key = UUID().uuidString

        // First upload
        var firstId: String?
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            firstId = try res.content.decode(RunResponse.self).id
        })

        // Duplicate upload — same idempotency key
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok) // 200, not 201
            let run = try res.content.decode(RunResponse.self)
            XCTAssertEqual(run.id, firstId)
        })

        // Only one run in DB
        let count = try await RunModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    func testUploadRun_invalidGPS_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badgps@test.com", password: "password123")

        let body = RunUploadRequest(
            id: UUID().uuidString,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 200,
            duration: 3600,
            averageHeartRate: 140,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [
                TrackPointServerDTO(latitude: 999, longitude: 6.86, altitudeM: 1200, timestamp: "2026-02-20T08:30:00Z", heartRate: nil)
            ],
            splits: [],
            notes: nil,
            linkedSessionId: nil,
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUploadRun_invalidDistance_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "baddist@test.com", password: "password123")

        let body = RunUploadRequest(
            id: UUID().uuidString,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 5000, // Exceeds 1000 max
            elevationGainM: 200,
            elevationLossM: 200,
            duration: 3600,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: nil,
            linkedSessionId: nil,
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUploadRun_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            try req.content.encode(validRunBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /runs (list)

    func testListRuns_empty_returnsEmptyPage() async throws {
        let user = try await app.registerUser(email: "empty@test.com", password: "password123")

        try await app.test(.GET, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let page = try res.content.decode(PaginatedResponse<RunResponse>.self)
            XCTAssertTrue(page.items.isEmpty)
            XCTAssertFalse(page.hasMore)
            XCTAssertNil(page.nextCursor)
        })
    }

    func testListRuns_returnsUserRuns() async throws {
        let user = try await app.registerUser(email: "list@test.com", password: "password123")

        // Upload 2 runs
        for _ in 0..<2 {
            try await app.test(.POST, "v1/runs", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(validRunBody())
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .created)
            })
        }

        try await app.test(.GET, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let page = try res.content.decode(PaginatedResponse<RunResponse>.self)
            XCTAssertEqual(page.items.count, 2)
        })
    }

    func testListRuns_pagination_respectsLimit() async throws {
        let user = try await app.registerUser(email: "pagelimit@test.com", password: "password123")

        // Upload 3 runs
        for _ in 0..<3 {
            try await app.test(.POST, "v1/runs", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(validRunBody())
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/runs?limit=2", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let page = try res.content.decode(PaginatedResponse<RunResponse>.self)
            XCTAssertEqual(page.items.count, 2)
            XCTAssertTrue(page.hasMore)
            XCTAssertNotNil(page.nextCursor)
        })
    }

    // MARK: - GET /runs/:runId

    func testGetRun_existing_returnsRun() async throws {
        let user = try await app.registerUser(email: "getrun@test.com", password: "password123")

        var runId: String?
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody())
        }, afterResponse: { res in
            runId = try res.content.decode(RunResponse.self).id
        })

        try await app.test(.GET, "v1/runs/\(runId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let run = try res.content.decode(RunResponse.self)
            XCTAssertEqual(run.id, runId)
            XCTAssertEqual(run.distanceKm, 42.2)
        })
    }

    func testGetRun_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "norun@test.com", password: "password123")

        try await app.test(.GET, "v1/runs/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testGetRun_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badid@test.com", password: "password123")

        try await app.test(.GET, "v1/runs/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - PUT /runs/:runId

    func testUpdateRun_valid_returnsUpdated() async throws {
        let user = try await app.registerUser(email: "update@test.com", password: "password123")
        let runId = UUID().uuidString
        let key = UUID().uuidString

        // Create
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody(id: runId, idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update with new distance
        let updatedBody = RunUploadRequest(
            id: runId,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 50.0,
            elevationGainM: 3000,
            elevationLossM: 3000,
            duration: 21600,
            averageHeartRate: 148,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 432,
            gpsTrack: [],
            splits: [],
            notes: "Updated notes",
            linkedSessionId: nil,
            idempotencyKey: key,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/runs/\(runId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updatedBody)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let run = try res.content.decode(RunResponse.self)
            XCTAssertEqual(run.distanceKm, 50.0)
            XCTAssertEqual(run.notes, "Updated notes")
        })
    }

    func testUpdateRun_conflictDetection_returnsConflict() async throws {
        let user = try await app.registerUser(email: "conflict@test.com", password: "password123")
        let runId = UUID().uuidString

        // Create
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody(id: runId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update with old clientUpdatedAt (before server's updatedAt)
        let conflictBody = RunUploadRequest(
            id: runId,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 50.0,
            elevationGainM: 3000,
            elevationLossM: 3000,
            duration: 21600,
            averageHeartRate: 148,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 432,
            gpsTrack: [],
            splits: [],
            notes: nil,
            linkedSessionId: nil,
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: "2020-01-01T00:00:00Z" // Very old date
        )

        try await app.test(.PUT, "v1/runs/\(runId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(conflictBody)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testUpdateRun_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "updnf@test.com", password: "password123")

        try await app.test(.PUT, "v1/runs/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - DELETE /runs/:runId

    func testDeleteRun_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "delrun@test.com", password: "password123")
        let runId = UUID().uuidString

        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validRunBody(id: runId))
        }, afterResponse: { _ in })

        try await app.test(.DELETE, "v1/runs/\(runId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Verify deleted
        let count = try await RunModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteRun_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "delnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/runs/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteRun_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/runs/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testRun_usersCannotAccessOtherRuns() async throws {
        let user1 = try await app.registerUser(email: "iso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "iso2@test.com", password: "password123")
        let runId = UUID().uuidString

        // User1 uploads a run
        try await app.test(.POST, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validRunBody(id: runId))
        }, afterResponse: { _ in })

        // User2 cannot GET it
        try await app.test(.GET, "v1/runs/\(runId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })

        // User2 cannot DELETE it
        try await app.test(.DELETE, "v1/runs/\(runId)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })

        // User2 list should be empty
        try await app.test(.GET, "v1/runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let page = try res.content.decode(PaginatedResponse<RunResponse>.self)
            XCTAssertTrue(page.items.isEmpty)
        })
    }
}
