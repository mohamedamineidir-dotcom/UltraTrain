@testable import App
import XCTVapor
import Fluent

final class NutritionControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validNutritionBody(
        nutritionPlanId: String = UUID().uuidString,
        raceId: String = UUID().uuidString,
        idempotencyKey: String = UUID().uuidString
    ) -> NutritionUpsertRequest {
        NutritionUpsertRequest(
            nutritionPlanId: nutritionPlanId,
            raceId: raceId,
            caloriesPerHour: 300,
            nutritionJson: "{\"gels\":3,\"water_ml\":500}",
            idempotencyKey: idempotencyKey,
            clientUpdatedAt: nil
        )
    }

    // MARK: - PUT /nutrition (Create)

    func testUpsertNutrition_create_returnsCreated() async throws {
        let user = try await app.registerUser(email: "nutcreate@test.com", password: "password123")

        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validNutritionBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let nutrition = try res.content.decode(NutritionResponse.self)
            XCTAssertEqual(nutrition.caloriesPerHour, 300)
            XCTAssertFalse(nutrition.id.isEmpty)
            XCTAssertFalse(nutrition.nutritionPlanId.isEmpty)
            XCTAssertFalse(nutrition.raceId.isEmpty)
        })
    }

    func testUpsertNutrition_update_returnsOk() async throws {
        let user = try await app.registerUser(email: "nutupdate@test.com", password: "password123")
        let planId = UUID().uuidString

        // Create
        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validNutritionBody(nutritionPlanId: planId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update same nutritionPlanId
        let updatedBody = NutritionUpsertRequest(
            nutritionPlanId: planId,
            raceId: UUID().uuidString,
            caloriesPerHour: 450,
            nutritionJson: "{\"gels\":5,\"water_ml\":700}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updatedBody)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let nutrition = try res.content.decode(NutritionResponse.self)
            XCTAssertEqual(nutrition.caloriesPerHour, 450)
            XCTAssertEqual(nutrition.nutritionPlanId, planId)
        })
    }

    func testUpsertNutrition_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            try req.content.encode(self.validNutritionBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUpsertNutrition_emptyPlanId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "nutempty@test.com", password: "password123")

        let body = NutritionUpsertRequest(
            nutritionPlanId: "",
            raceId: UUID().uuidString,
            caloriesPerHour: 300,
            nutritionJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertNutrition_emptyNutritionJson_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "nutjson@test.com", password: "password123")

        let body = NutritionUpsertRequest(
            nutritionPlanId: UUID().uuidString,
            raceId: UUID().uuidString,
            caloriesPerHour: 300,
            nutritionJson: "",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - GET /nutrition (List)

    func testListNutrition_empty_returnsEmptyItems() async throws {
        let user = try await app.registerUser(email: "nutlist@test.com", password: "password123")

        try await app.test(.GET, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<NutritionResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
            XCTAssertFalse(paginated.hasMore)
        })
    }

    func testListNutrition_withItems_returnsAll() async throws {
        let user = try await app.registerUser(email: "nutlistall@test.com", password: "password123")

        // Create two plans
        for _ in 0..<2 {
            try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(self.validNutritionBody())
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<NutritionResponse>.self)
            XCTAssertEqual(paginated.items.count, 2)
        })
    }

    func testListNutrition_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/nutrition", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - DELETE /nutrition/:nutritionId

    func testDeleteNutrition_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "nutdel@test.com", password: "password123")

        var nutritionId: String?
        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validNutritionBody())
        }, afterResponse: { res in
            nutritionId = try res.content.decode(NutritionResponse.self).id
        })

        try await app.test(.DELETE, "v1/nutrition/\(nutritionId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Verify deleted
        let count = try await NutritionPlanModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteNutrition_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "nutdelnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/nutrition/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteNutrition_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "nutdelbad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/nutrition/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testDeleteNutrition_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/nutrition/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testNutrition_userIsolation_cannotSeeOtherUsersPlans() async throws {
        let user1 = try await app.registerUser(email: "nutiso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "nutiso2@test.com", password: "password123")

        // User1 creates a plan
        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validNutritionBody())
        }, afterResponse: { _ in })

        // User2 should not see it
        try await app.test(.GET, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let paginated = try res.content.decode(PaginatedResponse<NutritionResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
        })
    }

    func testNutrition_userIsolation_cannotDeleteOtherUsersPlan() async throws {
        let user1 = try await app.registerUser(email: "nutisodel1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "nutisodel2@test.com", password: "password123")

        var nutritionId: String?
        try await app.test(.PUT, "v1/nutrition", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validNutritionBody())
        }, afterResponse: { res in
            nutritionId = try res.content.decode(NutritionResponse.self).id
        })

        // User2 cannot delete user1's plan
        try await app.test(.DELETE, "v1/nutrition/\(nutritionId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
