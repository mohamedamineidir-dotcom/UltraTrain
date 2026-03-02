@testable import App
import XCTVapor
import Fluent

final class FinishEstimateControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validEstimateBody(
        estimateId: String = UUID().uuidString,
        raceId: String = UUID().uuidString,
        idempotencyKey: String = UUID().uuidString
    ) -> FinishEstimateUpsertRequest {
        FinishEstimateUpsertRequest(
            estimateId: estimateId,
            raceId: raceId,
            expectedTime: 36000,
            confidencePercent: 75.0,
            estimateJson: "{\"optimistic\":32000,\"expected\":36000,\"conservative\":42000}",
            idempotencyKey: idempotencyKey,
            clientUpdatedAt: nil
        )
    }

    // MARK: - PUT /finish-estimates (Create)

    func testUpsertEstimate_create_returnsCreated() async throws {
        let user = try await app.registerUser(email: "estcreate@test.com", password: "password123")

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validEstimateBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let estimate = try res.content.decode(FinishEstimateResponse.self)
            XCTAssertEqual(estimate.expectedTime, 36000)
            XCTAssertEqual(estimate.confidencePercent, 75.0)
            XCTAssertFalse(estimate.id.isEmpty)
            XCTAssertFalse(estimate.estimateId.isEmpty)
            XCTAssertFalse(estimate.raceId.isEmpty)
        })
    }

    func testUpsertEstimate_update_returnsOk() async throws {
        let user = try await app.registerUser(email: "estupdate@test.com", password: "password123")
        let estId = UUID().uuidString

        // Create
        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validEstimateBody(estimateId: estId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Update same estimateId
        let updatedBody = FinishEstimateUpsertRequest(
            estimateId: estId,
            raceId: UUID().uuidString,
            expectedTime: 34000,
            confidencePercent: 80.0,
            estimateJson: "{\"optimistic\":30000,\"expected\":34000,\"conservative\":40000}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(updatedBody)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let estimate = try res.content.decode(FinishEstimateResponse.self)
            XCTAssertEqual(estimate.expectedTime, 34000)
            XCTAssertEqual(estimate.confidencePercent, 80.0)
            XCTAssertEqual(estimate.estimateId, estId)
        })
    }

    func testUpsertEstimate_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            try req.content.encode(self.validEstimateBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUpsertEstimate_emptyEstimateId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "estemptyid@test.com", password: "password123")

        let body = FinishEstimateUpsertRequest(
            estimateId: "",
            raceId: UUID().uuidString,
            expectedTime: 36000,
            confidencePercent: 75.0,
            estimateJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertEstimate_emptyRaceId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "estemptyrace@test.com", password: "password123")

        let body = FinishEstimateUpsertRequest(
            estimateId: UUID().uuidString,
            raceId: "",
            expectedTime: 36000,
            confidencePercent: 75.0,
            estimateJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertEstimate_negativeConfidence_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "estnegconf@test.com", password: "password123")

        let body = FinishEstimateUpsertRequest(
            estimateId: UUID().uuidString,
            raceId: UUID().uuidString,
            expectedTime: 36000,
            confidencePercent: -5.0,
            estimateJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpsertEstimate_confidenceOver100_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "estoverconf@test.com", password: "password123")

        let body = FinishEstimateUpsertRequest(
            estimateId: UUID().uuidString,
            raceId: UUID().uuidString,
            expectedTime: 36000,
            confidencePercent: 150.0,
            estimateJson: "{}",
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - GET /finish-estimates (List)

    func testListEstimates_empty_returnsEmptyItems() async throws {
        let user = try await app.registerUser(email: "estlist@test.com", password: "password123")

        try await app.test(.GET, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<FinishEstimateResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
            XCTAssertFalse(paginated.hasMore)
        })
    }

    func testListEstimates_withItems_returnsAll() async throws {
        let user = try await app.registerUser(email: "estlistall@test.com", password: "password123")

        for _ in 0..<2 {
            try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(self.validEstimateBody())
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let paginated = try res.content.decode(PaginatedResponse<FinishEstimateResponse>.self)
            XCTAssertEqual(paginated.items.count, 2)
        })
    }

    func testListEstimates_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/finish-estimates", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - DELETE /finish-estimates/:estimateId

    func testDeleteEstimate_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "estdel@test.com", password: "password123")

        var estimateServerId: String?
        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validEstimateBody())
        }, afterResponse: { res in
            estimateServerId = try res.content.decode(FinishEstimateResponse.self).id
        })

        try await app.test(.DELETE, "v1/finish-estimates/\(estimateServerId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        let count = try await FinishEstimateModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteEstimate_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "estdelnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/finish-estimates/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteEstimate_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "estdelbad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/finish-estimates/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testDeleteEstimate_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/finish-estimates/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testEstimate_userIsolation_cannotSeeOtherUsersEstimates() async throws {
        let user1 = try await app.registerUser(email: "estiso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "estiso2@test.com", password: "password123")

        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validEstimateBody())
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let paginated = try res.content.decode(PaginatedResponse<FinishEstimateResponse>.self)
            XCTAssertTrue(paginated.items.isEmpty)
        })
    }

    func testEstimate_userIsolation_cannotDeleteOtherUsersEstimate() async throws {
        let user1 = try await app.registerUser(email: "estisodel1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "estisodel2@test.com", password: "password123")

        var estimateServerId: String?
        try await app.test(.PUT, "v1/finish-estimates", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validEstimateBody())
        }, afterResponse: { res in
            estimateServerId = try res.content.decode(FinishEstimateResponse.self).id
        })

        try await app.test(.DELETE, "v1/finish-estimates/\(estimateServerId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
