@testable import App
import XCTVapor
import Fluent

final class ChallengeControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validChallengeBody(
        idempotencyKey: String = UUID().uuidString
    ) -> ChallengeCreateRequest {
        ChallengeCreateRequest(
            name: "Weekly 50K",
            descriptionText: "Run 50km this week",
            type: "distance",
            targetValue: 50.0,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-07T23:59:59Z",
            idempotencyKey: idempotencyKey
        )
    }

    // MARK: - POST /individual-challenges (Create)

    func testCreateChallenge_valid_returnsCreated() async throws {
        let user = try await app.registerUser(email: "ichalcreate@test.com", password: "password123")

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.name, "Weekly 50K")
            XCTAssertEqual(challenge.descriptionText, "Run 50km this week")
            XCTAssertEqual(challenge.type, "distance")
            XCTAssertEqual(challenge.targetValue, 50.0)
            XCTAssertEqual(challenge.currentValue, 0)
            XCTAssertEqual(challenge.status, "active")
            XCTAssertFalse(challenge.id.isEmpty)
        })
    }

    func testCreateChallenge_idempotent_returnsSame() async throws {
        let user = try await app.registerUser(email: "ichalidem@test.com", password: "password123")
        let key = UUID().uuidString

        var firstId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            firstId = try res.content.decode(ChallengeResponse.self).id
        })

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.id, firstId)
        })
    }

    func testCreateChallenge_endBeforeStart_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichaldate@test.com", password: "password123")

        let body = ChallengeCreateRequest(
            name: "Bad Dates",
            descriptionText: "Dates are wrong",
            type: "distance",
            targetValue: 50,
            startDate: "2026-04-01T00:00:00Z",
            endDate: "2026-03-01T00:00:00Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_invalidDateFormat_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichalbadd@test.com", password: "password123")

        let body = ChallengeCreateRequest(
            name: "Bad Date",
            descriptionText: "Invalid dates",
            type: "distance",
            targetValue: 50,
            startDate: "not-a-date",
            endDate: "also-not-a-date",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_emptyName_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichalname@test.com", password: "password123")

        let body = ChallengeCreateRequest(
            name: "",
            descriptionText: "No name",
            type: "distance",
            targetValue: 50,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-07T23:59:59Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_invalidType_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichaltype@test.com", password: "password123")

        let body = ChallengeCreateRequest(
            name: "Bad Type",
            descriptionText: "Invalid type",
            type: "swimming",
            targetValue: 50,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-07T23:59:59Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /individual-challenges (List)

    func testListChallenges_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "ichallist@test.com", password: "password123")

        try await app.test(.GET, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertTrue(challenges.isEmpty)
        })
    }

    func testListChallenges_withItems_returnsAll() async throws {
        let user = try await app.registerUser(email: "ichallistall@test.com", password: "password123")

        for _ in 0..<2 {
            try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: user.accessToken!)
                try req.content.encode(self.validChallengeBody())
            }, afterResponse: { _ in })
        }

        try await app.test(.GET, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertEqual(challenges.count, 2)
        })
    }

    func testListChallenges_statusFilter_filtersCorrectly() async throws {
        let user = try await app.registerUser(email: "ichalfilt@test.com", password: "password123")

        // Create one active challenge
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { _ in })

        // Filter by completed — should be empty
        try await app.test(.GET, "v1/individual-challenges?status=completed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertTrue(challenges.isEmpty)
        })

        // Filter by active — should have one
        try await app.test(.GET, "v1/individual-challenges?status=active", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertEqual(challenges.count, 1)
        })
    }

    func testListChallenges_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/individual-challenges", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /individual-challenges/:challengeId

    func testGetChallenge_existing_returnsChallenge() async throws {
        let user = try await app.registerUser(email: "ichalget@test.com", password: "password123")

        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(ChallengeResponse.self).id
        })

        try await app.test(.GET, "v1/individual-challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.id, challengeId)
            XCTAssertEqual(challenge.name, "Weekly 50K")
        })
    }

    func testGetChallenge_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "ichalgetnf@test.com", password: "password123")

        try await app.test(.GET, "v1/individual-challenges/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testGetChallenge_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichalgetbad@test.com", password: "password123")

        try await app.test(.GET, "v1/individual-challenges/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - PUT /individual-challenges/:challengeId/progress

    func testUpdateProgress_valid_updatesValue() async throws {
        let user = try await app.registerUser(email: "ichalprog@test.com", password: "password123")

        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(ChallengeResponse.self).id
        })

        try await app.test(.PUT, "v1/individual-challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChallengeUpdateProgressRequest(value: 25.5, idempotencyKey: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.currentValue, 25.5)
        })
    }

    func testUpdateProgress_inactiveChallenge_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichalprogbad@test.com", password: "password123")

        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(ChallengeResponse.self).id
        })

        // Manually set status to completed
        let challenge = try await ChallengeModel.find(UUID(uuidString: challengeId!)!, on: app.db)
        challenge!.status = "completed"
        try await challenge!.save(on: app.db)

        try await app.test(.PUT, "v1/individual-challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChallengeUpdateProgressRequest(value: 25.5, idempotencyKey: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateProgress_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "ichalprognf@test.com", password: "password123")

        try await app.test(.PUT, "v1/individual-challenges/\(UUID().uuidString)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChallengeUpdateProgressRequest(value: 10, idempotencyKey: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testUpdateProgress_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/individual-challenges/\(UUID().uuidString)/progress", beforeRequest: { req in
            try req.content.encode(ChallengeUpdateProgressRequest(value: 10, idempotencyKey: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - DELETE /individual-challenges/:challengeId

    func testDeleteChallenge_existing_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "ichaldel@test.com", password: "password123")

        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(ChallengeResponse.self).id
        })

        try await app.test(.DELETE, "v1/individual-challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        let count = try await ChallengeModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testDeleteChallenge_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "ichaldelnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/individual-challenges/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testDeleteChallenge_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "ichaldelbad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/individual-challenges/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testDeleteChallenge_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/individual-challenges/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testChallenge_userIsolation_cannotSeeOtherUsersChallenges() async throws {
        let user1 = try await app.registerUser(email: "ichaliso1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "ichaliso2@test.com", password: "password123")

        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertTrue(challenges.isEmpty)
        })
    }

    func testChallenge_userIsolation_cannotDeleteOtherUsersChallenge() async throws {
        let user1 = try await app.registerUser(email: "ichalisodel1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "ichalisodel2@test.com", password: "password123")

        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(ChallengeResponse.self).id
        })

        try await app.test(.DELETE, "v1/individual-challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - Full Flow

    func testChallengeFlow_createProgressDelete() async throws {
        let user = try await app.registerUser(email: "ichalflow@test.com", password: "password123")

        // 1. Create challenge
        var challengeId: String?
        try await app.test(.POST, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let challenge = try res.content.decode(ChallengeResponse.self)
            challengeId = challenge.id
            XCTAssertEqual(challenge.currentValue, 0)
        })

        // 2. Update progress
        try await app.test(.PUT, "v1/individual-challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChallengeUpdateProgressRequest(value: 30.0, idempotencyKey: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.currentValue, 30.0)
        })

        // 3. Get individual challenge
        try await app.test(.GET, "v1/individual-challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(ChallengeResponse.self)
            XCTAssertEqual(challenge.currentValue, 30.0)
            XCTAssertEqual(challenge.name, "Weekly 50K")
        })

        // 4. List challenges
        try await app.test(.GET, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertEqual(challenges.count, 1)
        })

        // 5. Delete challenge
        try await app.test(.DELETE, "v1/individual-challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // 6. Verify deleted
        try await app.test(.GET, "v1/individual-challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            let challenges = try res.content.decode([ChallengeResponse].self)
            XCTAssertTrue(challenges.isEmpty)
        })
    }
}
