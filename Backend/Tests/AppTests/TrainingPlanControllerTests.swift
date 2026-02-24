@testable import App
import XCTVapor
import Fluent

final class TrainingPlanControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validPlanBody(
        idempotencyKey: String = UUID().uuidString
    ) -> TrainingPlanUploadRequest {
        TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "UTMB",
            targetRaceDate: "2026-08-28T18:00:00Z",
            totalWeeks: 16,
            planJson: "{\"weeks\":[{\"number\":1,\"phase\":\"base\"}]}",
            idempotencyKey: idempotencyKey
        )
    }

    // MARK: - PUT /training-plan (Create)

    func testUpsertPlan_create_returnsCreated() async throws {
        let user = try await app.registerUser(email: "plan@test.com", password: "password123")

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validPlanBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let plan = try res.content.decode(TrainingPlanResponse.self)
            XCTAssertEqual(plan.targetRaceName, "UTMB")
            XCTAssertEqual(plan.totalWeeks, 16)
            XCTAssertFalse(plan.id.isEmpty)
            XCTAssertFalse(plan.planJson.isEmpty)
        })
    }

    // MARK: - PUT /training-plan (Upsert)

    func testUpsertPlan_update_returnsOk() async throws {
        let user = try await app.registerUser(email: "upplan@test.com", password: "password123")

        // Create
        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validPlanBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update
        let updated = TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "CCC",
            targetRaceDate: "2026-08-27T09:00:00Z",
            totalWeeks: 12,
            planJson: "{\"weeks\":[{\"number\":1,\"phase\":\"build\"}]}",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updated)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let plan = try res.content.decode(TrainingPlanResponse.self)
            XCTAssertEqual(plan.targetRaceName, "CCC")
            XCTAssertEqual(plan.totalWeeks, 12)
        })

        // Only one plan per user
        let count = try await TrainingPlanModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    // MARK: - PUT /training-plan (Validation)

    func testUpsertPlan_invalidWeeks_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badweeks@test.com", password: "password123")

        let body = TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "Test",
            targetRaceDate: "2026-08-28T18:00:00Z",
            totalWeeks: 100, // Exceeds 52 max
            planJson: "{}",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertPlan_emptyName_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "emptyname@test.com", password: "password123")

        let body = TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "",
            targetRaceDate: "2026-08-28T18:00:00Z",
            totalWeeks: 16,
            planJson: "{}",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertPlan_invalidDate_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "plandate@test.com", password: "password123")

        let body = TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "UTMB",
            targetRaceDate: "not-a-date",
            totalWeeks: 16,
            planJson: "{}",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertPlan_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            try req.content.encode(validPlanBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /training-plan

    func testGetPlan_noPlan_returnsNotFound() async throws {
        let user = try await app.registerUser(email: "noplan@test.com", password: "password123")

        try await app.test(.GET, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testGetPlan_existing_returnsPlan() async throws {
        let user = try await app.registerUser(email: "getplan@test.com", password: "password123")

        // Create
        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validPlanBody())
        }, afterResponse: { _ in })

        // Get
        try await app.test(.GET, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let plan = try res.content.decode(TrainingPlanResponse.self)
            XCTAssertEqual(plan.targetRaceName, "UTMB")
            XCTAssertEqual(plan.totalWeeks, 16)
        })
    }

    func testGetPlan_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/training-plan", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testPlan_usersCannotSeeOtherPlans() async throws {
        let user1 = try await app.registerUser(email: "piso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "piso2@test.com", password: "password123")

        // User1 creates plan
        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validPlanBody())
        }, afterResponse: { _ in })

        // User2 should not see it
        try await app.test(.GET, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - Full Flow

    func testPlanFlow_createGetUpdate() async throws {
        let user = try await app.registerUser(email: "flow@test.com", password: "password123")

        // 1. No plan initially
        try await app.test(.GET, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })

        // 2. Create
        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validPlanBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // 3. Get
        try await app.test(.GET, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let plan = try res.content.decode(TrainingPlanResponse.self)
            XCTAssertEqual(plan.targetRaceName, "UTMB")
        })

        // 4. Update
        let newPlan = TrainingPlanUploadRequest(
            planId: UUID().uuidString,
            targetRaceName: "Hardrock 100",
            targetRaceDate: "2026-07-18T06:00:00Z",
            totalWeeks: 20,
            planJson: "{\"weeks\":[]}",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.PUT, "v1/training-plan", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(newPlan)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let plan = try res.content.decode(TrainingPlanResponse.self)
            XCTAssertEqual(plan.targetRaceName, "Hardrock 100")
            XCTAssertEqual(plan.totalWeeks, 20)
        })
    }
}
