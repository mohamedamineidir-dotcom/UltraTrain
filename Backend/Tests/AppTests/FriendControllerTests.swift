@testable import App
import XCTVapor
import Fluent

final class FriendControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - POST /friends/request

    func testSendRequest_valid_returnsCreated() async throws {
        let user1 = try await app.registerUser(email: "req1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "req2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "req2@test.com")

        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let conn = try res.content.decode(FriendConnectionResponse.self)
            XCTAssertEqual(conn.status, "pending")
            XCTAssertEqual(conn.friendProfileId, user2Id.uuidString)
            XCTAssertFalse(conn.id.isEmpty)
        })
    }

    func testSendRequest_toSelf_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "self@test.com", password: "password123")
        let userId = try await app.getUserId(email: "self@test.com")

        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: userId.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testSendRequest_nonexistentUser_returnsNotFound() async throws {
        let user = try await app.registerUser(email: "lonely@test.com", password: "password123")

        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testSendRequest_duplicate_returnsConflict() async throws {
        let user1 = try await app.registerUser(email: "dup1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "dup2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "dup2@test.com")

        // First request
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Duplicate request
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testSendRequest_alreadyFriends_returnsConflict() async throws {
        let user1 = try await app.registerUser(email: "af1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "af2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "af2@test.com")

        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        // Try to send another request
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testSendRequest_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            try req.content.encode(FriendRequestRequest(recipientProfileId: UUID().uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - PUT /friends/:connectionId/accept

    func testAcceptRequest_asRecipient_succeeds() async throws {
        let user1 = try await app.registerUser(email: "acc1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "acc2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "acc2@test.com")

        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        try await app.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let conn = try res.content.decode(FriendConnectionResponse.self)
            XCTAssertEqual(conn.status, "accepted")
            XCTAssertNotNil(conn.acceptedDate)
        })
    }

    func testAcceptRequest_asRequestor_returnsForbidden() async throws {
        let user1 = try await app.registerUser(email: "noaccept1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "noaccept2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "noaccept2@test.com")

        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        // Requestor tries to accept their own request
        try await app.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .forbidden)
        })
    }

    func testAcceptRequest_alreadyAccepted_returnsBadRequest() async throws {
        let user1 = try await app.registerUser(email: "aa1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "aa2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "aa2@test.com")

        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        // Accept
        try await app.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { _ in })

        // Try to accept again
        try await app.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testAcceptRequest_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "accnf@test.com", password: "password123")

        try await app.test(.PUT, "v1/friends/\(UUID().uuidString)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    // MARK: - PUT /friends/:connectionId/decline

    func testDeclineRequest_asRecipient_succeeds() async throws {
        let user1 = try await app.registerUser(email: "dec1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "dec2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "dec2@test.com")

        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        try await app.test(.PUT, "v1/friends/\(connectionId!)/decline", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let conn = try res.content.decode(FriendConnectionResponse.self)
            XCTAssertEqual(conn.status, "declined")
        })
    }

    func testDeclineRequest_asRequestor_returnsForbidden() async throws {
        let user1 = try await app.registerUser(email: "nodec1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "nodec2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "nodec2@test.com")

        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        try await app.test(.PUT, "v1/friends/\(connectionId!)/decline", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .forbidden)
        })
    }

    // MARK: - GET /friends

    func testListFriends_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "nofriends@test.com", password: "password123")

        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertTrue(friends.isEmpty)
        })
    }

    func testListFriends_withAcceptedFriends_returnsList() async throws {
        let user1 = try await app.registerUser(email: "lf1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "lf2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "lf2@test.com")

        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertEqual(friends.count, 1)
            XCTAssertEqual(friends[0].status, "accepted")
            XCTAssertEqual(friends[0].friendProfileId, user2Id.uuidString)
        })
    }

    func testListFriends_excludesPending() async throws {
        let user1 = try await app.registerUser(email: "ep1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "ep2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "ep2@test.com")

        // Send request but don't accept
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { _ in })

        // Friends list should be empty (pending is not accepted)
        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertTrue(friends.isEmpty)
        })
    }

    func testListFriends_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/friends", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /friends/pending

    func testListPending_showsIncomingRequests() async throws {
        let user1 = try await app.registerUser(email: "pend1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "pend2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "pend2@test.com")

        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { _ in })

        // User2 should see the pending request
        try await app.test(.GET, "v1/friends/pending", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let pending = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertEqual(pending.count, 1)
            XCTAssertEqual(pending[0].status, "pending")
        })

        // User1 (requestor) should NOT see it in their pending list
        try await app.test(.GET, "v1/friends/pending", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let pending = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertTrue(pending.isEmpty)
        })
    }

    // MARK: - DELETE /friends/:connectionId

    func testRemoveFriend_asRequestor_succeeds() async throws {
        let user1 = try await app.registerUser(email: "rm1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "rm2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "rm2@test.com")

        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        // Get the connection ID from the friends list
        var connectionId: String?
        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            connectionId = friends[0].id
        })

        try await app.test(.DELETE, "v1/friends/\(connectionId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Verify removed
        let count = try await FriendConnectionModel.query(on: app.db).count()
        XCTAssertEqual(count, 0)
    }

    func testRemoveFriend_asRecipient_succeeds() async throws {
        let user1 = try await app.registerUser(email: "rmr1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "rmr2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "rmr2@test.com")

        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        var connectionId: String?
        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            connectionId = friends[0].id
        })

        try await app.test(.DELETE, "v1/friends/\(connectionId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }

    func testRemoveFriend_notFound_returns404() async throws {
        let user = try await app.registerUser(email: "rmnf@test.com", password: "password123")

        try await app.test(.DELETE, "v1/friends/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testRemoveFriend_invalidId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "rmbad@test.com", password: "password123")

        try await app.test(.DELETE, "v1/friends/not-a-uuid", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testRemoveFriend_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/friends/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Full Flow

    func testFriendshipFlow_requestAcceptListRemove() async throws {
        let user1 = try await app.registerUser(email: "flow1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "flow2@test.com", password: "password123")
        let user2Id = try await app.getUserId(email: "flow2@test.com")

        // 1. Send request
        var connectionId: String?
        try await app.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(FriendRequestRequest(recipientProfileId: user2Id.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            connectionId = try res.content.decode(FriendConnectionResponse.self).id
        })

        // 2. Pending shows for recipient
        try await app.test(.GET, "v1/friends/pending", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let pending = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertEqual(pending.count, 1)
        })

        // 3. Accept
        try await app.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // 4. Both see each other in friends list
        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertEqual(friends.count, 1)
            XCTAssertEqual(friends[0].status, "accepted")
        })

        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertEqual(friends.count, 1)
        })

        // 5. Remove
        try await app.test(.DELETE, "v1/friends/\(connectionId!)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // 6. Friends list now empty for both
        try await app.test(.GET, "v1/friends", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let friends = try res.content.decode([FriendConnectionResponse].self)
            XCTAssertTrue(friends.isEmpty)
        })
    }
}
