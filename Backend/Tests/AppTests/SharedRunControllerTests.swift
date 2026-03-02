@testable import App
import XCTVapor
import Fluent

final class SharedRunControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validShareBody(
        recipientIds: [String],
        idempotencyKey: String = UUID().uuidString
    ) -> ShareRunRequest {
        ShareRunRequest(
            id: UUID().uuidString,
            date: "2026-02-20T08:30:00Z",
            distanceKm: 42.2,
            elevationGainM: 2500,
            elevationLossM: 2500,
            duration: 18000,
            averagePace: 426,
            gpsTrack: [
                TrackPointServerDTO(latitude: 45.8, longitude: 6.86, altitudeM: 1200, timestamp: "2026-02-20T08:30:00Z", heartRate: 140)
            ],
            splits: [
                SplitServerDTO(id: UUID().uuidString, kilometerNumber: 1, duration: 420, elevationChangeM: 50, averageHeartRate: 145)
            ],
            notes: "Great trail run",
            recipientProfileIds: recipientIds,
            idempotencyKey: idempotencyKey
        )
    }

    /// Set up two users who are friends and return their tokens and the friend's user ID.
    private func setupFriendPair() async throws -> (sharer: TestUser, friend: TestUser, friendId: UUID) {
        let sharer = try await app.registerUser(email: "sharer-\(UUID().uuidString.prefix(8))@test.com", password: "password123")
        let friend = try await app.registerUser(email: "friend-\(UUID().uuidString.prefix(8))@test.com", password: "password123")
        try await app.createAthleteProfile(token: sharer.accessToken!, firstName: "Sharer", lastName: "One")
        try await app.createAthleteProfile(token: friend.accessToken!, firstName: "Friend", lastName: "Two")
        let friendId = try await app.getUserId(email: friend.email)
        try await app.establishFriendship(
            requestorToken: sharer.accessToken!,
            recipientToken: friend.accessToken!,
            recipientUserId: friendId
        )
        return (sharer, friend, friendId)
    }

    // MARK: - POST /shared-runs (Share)

    func testShareRun_valid_returnsCreated() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()

        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let run = try res.content.decode(SharedRunResponse.self)
            XCTAssertEqual(run.distanceKm, 42.2)
            XCTAssertEqual(run.elevationGainM, 2500)
            XCTAssertEqual(run.notes, "Great trail run")
            XCTAssertFalse(run.id.isEmpty)
        })
    }

    func testShareRun_idempotent_returnsSame() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()
        let key = UUID().uuidString

        var firstId: String?
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString], idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            firstId = try res.content.decode(SharedRunResponse.self).id
        })

        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString], idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let run = try res.content.decode(SharedRunResponse.self)
            XCTAssertEqual(run.id, firstId)
        })
    }

    func testShareRun_withNonFriend_returnsBadRequest() async throws {
        let user1 = try await app.registerUser(email: "sharenf1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "sharenf2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!)
        let user2Id = try await app.getUserId(email: "sharenf2@test.com")

        // NOT friends
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [user2Id.uuidString]))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testShareRun_emptyRecipients_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "shareemp@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: []))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testShareRun_invalidDate_returnsBadRequest() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()

        let body = ShareRunRequest(
            id: UUID().uuidString,
            date: "not-a-date",
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 200,
            duration: 3600,
            averagePace: 360,
            gpsTrack: [],
            splits: [],
            notes: nil,
            recipientProfileIds: [friendId.uuidString],
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testShareRun_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            try req.content.encode(self.validShareBody(recipientIds: [UUID().uuidString]))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /shared-runs (Shared With Me)

    func testListSharedWithMe_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "noshares@test.com", password: "password123")

        try await app.test(.GET, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let runs = try res.content.decode([SharedRunResponse].self)
            XCTAssertTrue(runs.isEmpty)
        })
    }

    func testListSharedWithMe_returnsSharedRuns() async throws {
        let (sharer, friend, friendId) = try await setupFriendPair()

        // Sharer shares a run with friend
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { _ in })

        // Friend sees it
        try await app.test(.GET, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: friend.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let runs = try res.content.decode([SharedRunResponse].self)
            XCTAssertEqual(runs.count, 1)
            XCTAssertEqual(runs[0].distanceKm, 42.2)
        })
    }

    func testListSharedWithMe_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/shared-runs", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /shared-runs/mine

    func testListMySharedRuns_returnsOwnShares() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()

        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/shared-runs/mine", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let runs = try res.content.decode([SharedRunResponse].self)
            XCTAssertEqual(runs.count, 1)
        })
    }

    func testListMySharedRuns_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "nomine@test.com", password: "password123")

        try await app.test(.GET, "v1/shared-runs/mine", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let runs = try res.content.decode([SharedRunResponse].self)
            XCTAssertTrue(runs.isEmpty)
        })
    }

    // MARK: - DELETE /shared-runs/:sharedRunId (Revoke)

    func testRevokeShare_asSharer_succeeds() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()

        var sharedRunId: String?
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { res in
            sharedRunId = try res.content.decode(SharedRunResponse.self).id
        })

        try await app.test(.DELETE, "v1/shared-runs/\(sharedRunId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Verify deleted
        let count = try await SharedRunModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
        let recipientCount = try await SharedRunRecipientModel.query(on: app.db).count()
        XCTAssertEqual(recipientCount, 0)
    }

    func testRevokeShare_asRecipient_returnsForbidden() async throws {
        let (sharer, friend, friendId) = try await setupFriendPair()

        var sharedRunId: String?
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { res in
            sharedRunId = try res.content.decode(SharedRunResponse.self).id
        })

        // Recipient cannot revoke
        try await app.test(.DELETE, "v1/shared-runs/\(sharedRunId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: friend.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .forbidden)
        })
    }

    func testRevokeShare_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "revokenf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/shared-runs/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testRevokeShare_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "revokebad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/shared-runs/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testRevokeShare_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/shared-runs/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - User Isolation

    func testSharedRun_nonRecipientCannotSee() async throws {
        let (sharer, _, friendId) = try await setupFriendPair()
        let outsider = try await app.registerUser(email: "outsider@test.com", password: "password123")

        // Sharer shares with friend
        try await app.test(.POST, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: sharer.accessToken!)
            try req.content.encode(self.validShareBody(recipientIds: [friendId.uuidString]))
        }, afterResponse: { _ in })

        // Outsider should not see it
        try await app.test(.GET, "v1/shared-runs", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: outsider.accessToken!)
        }, afterResponse: { res in
            let runs = try res.content.decode([SharedRunResponse].self)
            XCTAssertTrue(runs.isEmpty)
        })
    }
}
