@testable import App
import XCTVapor
import Fluent

final class GroupChallengeControllerTests: XCTestCase {

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
    ) -> CreateChallengeRequest {
        CreateChallengeRequest(
            name: "March Mileage",
            descriptionText: "Run 100km in March",
            type: "distance",
            targetValue: 100.0,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-31T23:59:59Z",
            idempotencyKey: idempotencyKey
        )
    }

    // MARK: - POST /challenges (Create)

    func testCreateChallenge_valid_returnsCreated() async throws {
        let user = try await app.registerUser(email: "chal@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)
        let userId = try await app.getUserId(email: "chal@test.com")

        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let challenge = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(challenge.name, "March Mileage")
            XCTAssertEqual(challenge.descriptionText, "Run 100km in March")
            XCTAssertEqual(challenge.type, "distance")
            XCTAssertEqual(challenge.targetValue, 100.0)
            XCTAssertEqual(challenge.status, "active")
            XCTAssertEqual(challenge.creatorProfileId, userId.uuidString)
            XCTAssertFalse(challenge.id.isEmpty)
            // Creator is auto-added as participant
            XCTAssertEqual(challenge.participants.count, 1)
            XCTAssertEqual(challenge.participants[0].currentValue, 0)
        })
    }

    func testCreateChallenge_idempotent_returnsSame() async throws {
        let user = try await app.registerUser(email: "chalidem@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)
        let key = UUID().uuidString

        // First create
        var firstId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            firstId = try res.content.decode(GroupChallengeResponse.self).id
        })

        // Duplicate
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok) // 200, not 201
            let challenge = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(challenge.id, firstId)
        })
    }

    func testCreateChallenge_endBeforeStart_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "chaldate@test.com", password: "password123")

        let body = CreateChallengeRequest(
            name: "Bad Challenge",
            descriptionText: "Dates are wrong",
            type: "distance",
            targetValue: 50,
            startDate: "2026-04-01T00:00:00Z",
            endDate: "2026-03-01T00:00:00Z",  // Before start
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_invalidDateFormat_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "chalbadd@test.com", password: "password123")

        let body = CreateChallengeRequest(
            name: "Bad Date",
            descriptionText: "Invalid dates",
            type: "distance",
            targetValue: 50,
            startDate: "not-a-date",
            endDate: "also-not-a-date",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_emptyName_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "chalname@test.com", password: "password123")

        let body = CreateChallengeRequest(
            name: "",
            descriptionText: "No name",
            type: "distance",
            targetValue: 50,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-31T23:59:59Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_invalidType_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "chaltype@test.com", password: "password123")

        let body = CreateChallengeRequest(
            name: "Bad Type",
            descriptionText: "Invalid type",
            type: "swimming",  // Not in allowed list
            targetValue: 50,
            startDate: "2026-03-01T00:00:00Z",
            endDate: "2026-03-31T23:59:59Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateChallenge_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            try req.content.encode(self.validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /challenges

    func testListChallenges_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "nochal@test.com", password: "password123")

        try await app.test(.GET, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenges = try res.content.decode([GroupChallengeResponse].self)
            XCTAssertTrue(challenges.isEmpty)
        })
    }

    func testListChallenges_returnsParticipatingChallenges() async throws {
        let user = try await app.registerUser(email: "listchal@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        // Create a challenge (creator is auto-participant)
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenges = try res.content.decode([GroupChallengeResponse].self)
            XCTAssertEqual(challenges.count, 1)
            XCTAssertEqual(challenges[0].name, "March Mileage")
        })
    }

    func testListChallenges_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/challenges", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /challenges/:challengeId

    func testGetChallenge_existing_returnsChallenge() async throws {
        let user = try await app.registerUser(email: "getchal@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        try await app.test(.GET, "v1/challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(challenge.id, challengeId)
            XCTAssertEqual(challenge.name, "March Mileage")
        })
    }

    func testGetChallenge_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "getnfchal@test.com", password: "password123")

        try await app.test(.GET, "v1/challenges/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testGetChallenge_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "getbadchal@test.com", password: "password123")

        try await app.test(.GET, "v1/challenges/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - POST /challenges/:challengeId/join

    func testJoinChallenge_valid_addsParticipant() async throws {
        let user1 = try await app.registerUser(email: "join1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "join2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!, firstName: "Creator", lastName: "One")
        try await app.createAthleteProfile(token: user2.accessToken!, firstName: "Joiner", lastName: "Two")

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        try await app.test(.POST, "v1/challenges/\(challengeId!)/join", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let challenge = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(challenge.participants.count, 2)
        })
    }

    func testJoinChallenge_alreadyParticipant_returnsConflict() async throws {
        let user = try await app.registerUser(email: "joindup@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        // Try to join again (creator is already a participant)
        try await app.test(.POST, "v1/challenges/\(challengeId!)/join", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testJoinChallenge_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "joinnf@test.com", password: "password123")

        try await app.test(.POST, "v1/challenges/\(UUID().uuidString)/join", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - POST /challenges/:challengeId/leave

    func testLeaveChallenge_asNonCreator_succeeds() async throws {
        let user1 = try await app.registerUser(email: "leave1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "leave2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!)
        try await app.createAthleteProfile(token: user2.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        // User2 joins
        try await app.test(.POST, "v1/challenges/\(challengeId!)/join", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { _ in })

        // User2 leaves
        try await app.test(.POST, "v1/challenges/\(challengeId!)/leave", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Verify only creator remains
        let participants = try await ChallengeParticipantModel.query(on: app.db)
            .filter(\.$challenge.$id == UUID(uuidString: challengeId!)!)
            .count()
        XCTAssertEqual(participants, 1)
    }

    func testLeaveChallenge_asCreator_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "leavecreator@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        try await app.test(.POST, "v1/challenges/\(challengeId!)/leave", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testLeaveChallenge_notParticipant_returnsNotFound() async throws {
        let user1 = try await app.registerUser(email: "leavenp1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "leavenp2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        // User2 never joined, tries to leave
        try await app.test(.POST, "v1/challenges/\(challengeId!)/leave", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - PUT /challenges/:challengeId/progress

    func testUpdateProgress_valid_updatesValue() async throws {
        let user = try await app.registerUser(email: "prog@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        try await app.test(.PUT, "v1/challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(UpdateProgressRequest(value: 42.5))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let participant = try res.content.decode(ChallengeParticipantResponse.self)
            XCTAssertEqual(participant.currentValue, 42.5)
        })
    }

    func testUpdateProgress_notParticipant_returnsNotFound() async throws {
        let user1 = try await app.registerUser(email: "prognp1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "prognp2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!)

        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        try await app.test(.PUT, "v1/challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
            try req.content.encode(UpdateProgressRequest(value: 10))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testUpdateProgress_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/challenges/\(UUID().uuidString)/progress", beforeRequest: { req in
            try req.content.encode(UpdateProgressRequest(value: 10))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Full Flow

    func testChallengeFlow_createJoinProgressLeave() async throws {
        let creator = try await app.registerUser(email: "cflow1@test.com", password: "password123")
        let joiner = try await app.registerUser(email: "cflow2@test.com", password: "password123")
        try await app.createAthleteProfile(token: creator.accessToken!, firstName: "Creator", lastName: "C")
        try await app.createAthleteProfile(token: joiner.accessToken!, firstName: "Joiner", lastName: "J")

        // 1. Create challenge
        var challengeId: String?
        try await app.test(.POST, "v1/challenges", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: creator.accessToken!)
            try req.content.encode(validChallengeBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            challengeId = try res.content.decode(GroupChallengeResponse.self).id
        })

        // 2. Joiner joins
        try await app.test(.POST, "v1/challenges/\(challengeId!)/join", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: joiner.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let c = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(c.participants.count, 2)
        })

        // 3. Both update progress
        try await app.test(.PUT, "v1/challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: creator.accessToken!)
            try req.content.encode(UpdateProgressRequest(value: 50))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try await app.test(.PUT, "v1/challenges/\(challengeId!)/progress", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: joiner.accessToken!)
            try req.content.encode(UpdateProgressRequest(value: 75))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // 4. Verify both in list
        try await app.test(.GET, "v1/challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: creator.accessToken!)
        }, afterResponse: { res in
            let c = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(c.participants.count, 2)
        })

        // 5. Joiner leaves
        try await app.test(.POST, "v1/challenges/\(challengeId!)/leave", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: joiner.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // 6. Only creator remains
        try await app.test(.GET, "v1/challenges/\(challengeId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: creator.accessToken!)
        }, afterResponse: { res in
            let c = try res.content.decode(GroupChallengeResponse.self)
            XCTAssertEqual(c.participants.count, 1)
        })
    }
}
