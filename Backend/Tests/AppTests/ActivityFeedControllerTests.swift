@testable import App
import XCTVapor
import Fluent

final class ActivityFeedControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validActivityBody(
        idempotencyKey: String = UUID().uuidString
    ) -> PublishActivityRequest {
        PublishActivityRequest(
            activityType: "completedRun",
            title: "Morning Trail Run",
            subtitle: "10K in the mountains",
            distanceKm: 10.5,
            elevationGainM: 500,
            duration: 3600,
            averagePace: 342,
            timestamp: "2026-02-20T08:30:00Z",
            idempotencyKey: idempotencyKey
        )
    }

    // MARK: - POST /feed (Publish Activity)

    func testPublishActivity_valid_returnsCreated() async throws {
        let user = try await app.registerUser(email: "pub@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let item = try res.content.decode(ActivityFeedItemResponse.self)
            XCTAssertEqual(item.activityType, "completedRun")
            XCTAssertEqual(item.title, "Morning Trail Run")
            XCTAssertEqual(item.subtitle, "10K in the mountains")
            XCTAssertEqual(item.distanceKm, 10.5)
            XCTAssertEqual(item.likeCount, 0)
            XCTAssertFalse(item.isLikedByMe)
            XCTAssertFalse(item.id.isEmpty)
        })
    }

    func testPublishActivity_idempotent_returnsSameItem() async throws {
        let user = try await app.registerUser(email: "idem@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)
        let key = UUID().uuidString

        // First publish
        var firstId: String?
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            firstId = try res.content.decode(ActivityFeedItemResponse.self).id
        })

        // Duplicate publish
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody(idempotencyKey: key))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok) // 200, not 201
            let item = try res.content.decode(ActivityFeedItemResponse.self)
            XCTAssertEqual(item.id, firstId)
        })

        // Only one item in DB
        let count = try await ActivityFeedItemModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    func testPublishActivity_invalidTimestamp_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badts@test.com", password: "password123")

        let body = PublishActivityRequest(
            activityType: "completedRun",
            title: "Test",
            subtitle: nil,
            distanceKm: nil,
            elevationGainM: nil,
            duration: nil,
            averagePace: nil,
            timestamp: "not-a-date",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testPublishActivity_invalidType_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badtype@test.com", password: "password123")

        let body = PublishActivityRequest(
            activityType: "invalidType",
            title: "Test",
            subtitle: nil,
            distanceKm: nil,
            elevationGainM: nil,
            duration: nil,
            averagePace: nil,
            timestamp: "2026-02-20T08:30:00Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testPublishActivity_emptyTitle_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "notitle@test.com", password: "password123")

        let body = PublishActivityRequest(
            activityType: "completedRun",
            title: "",
            subtitle: nil,
            distanceKm: nil,
            elevationGainM: nil,
            duration: nil,
            averagePace: nil,
            timestamp: "2026-02-20T08:30:00Z",
            idempotencyKey: UUID().uuidString
        )

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testPublishActivity_emptyIdempotencyKey_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "nokey@test.com", password: "password123")

        let body = PublishActivityRequest(
            activityType: "completedRun",
            title: "Test",
            subtitle: nil,
            distanceKm: nil,
            elevationGainM: nil,
            duration: nil,
            averagePace: nil,
            timestamp: "2026-02-20T08:30:00Z",
            idempotencyKey: ""
        )

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testPublishActivity_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            try req.content.encode(self.validActivityBody())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - GET /feed

    func testGetFeed_empty_returnsEmptyArray() async throws {
        let user = try await app.registerUser(email: "emptyfeed@test.com", password: "password123")

        try await app.test(.GET, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let items = try res.content.decode([ActivityFeedItemResponse].self)
            XCTAssertTrue(items.isEmpty)
        })
    }

    func testGetFeed_returnsOwnActivities() async throws {
        let user = try await app.registerUser(email: "ownfeed@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { _ in })

        try await app.test(.GET, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let items = try res.content.decode([ActivityFeedItemResponse].self)
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0].title, "Morning Trail Run")
        })
    }

    func testGetFeed_includesFriendActivities() async throws {
        let user1 = try await app.registerUser(email: "feed1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "feed2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!, firstName: "Alice", lastName: "Runner")
        try await app.createAthleteProfile(token: user2.accessToken!, firstName: "Bob", lastName: "Runner")
        let user2Id = try await app.getUserId(email: "feed2@test.com")

        // Establish friendship
        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        // User2 publishes an activity
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { _ in })

        // User1 should see it in their feed
        try await app.test(.GET, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let items = try res.content.decode([ActivityFeedItemResponse].self)
            XCTAssertEqual(items.count, 1)
        })
    }

    func testGetFeed_excludesNonFriendActivities() async throws {
        let user1 = try await app.registerUser(email: "nonfriend1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "nonfriend2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user2.accessToken!)

        // User2 publishes, but they are NOT friends
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { _ in })

        // User1 should NOT see it
        try await app.test(.GET, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { res in
            let items = try res.content.decode([ActivityFeedItemResponse].self)
            XCTAssertTrue(items.isEmpty)
        })
    }

    func testGetFeed_noAuth_returnsUnauthorized() async throws {
        try await app.test(.GET, "v1/feed", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - POST /feed/:itemId/like (Toggle Like)

    func testToggleLike_likeItem_returnsLiked() async throws {
        let user = try await app.registerUser(email: "like@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        // Publish activity
        var itemId: String?
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { res in
            itemId = try res.content.decode(ActivityFeedItemResponse.self).id
        })

        // Like it
        try await app.test(.POST, "v1/feed/\(itemId!)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let like = try res.content.decode(LikeResponse.self)
            XCTAssertTrue(like.liked)
            XCTAssertEqual(like.likeCount, 1)
        })
    }

    func testToggleLike_unlikeItem_returnsUnliked() async throws {
        let user = try await app.registerUser(email: "unlike@test.com", password: "password123")
        try await app.createAthleteProfile(token: user.accessToken!)

        var itemId: String?
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { res in
            itemId = try res.content.decode(ActivityFeedItemResponse.self).id
        })

        // Like
        try await app.test(.POST, "v1/feed/\(itemId!)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { _ in })

        // Unlike (toggle)
        try await app.test(.POST, "v1/feed/\(itemId!)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let like = try res.content.decode(LikeResponse.self)
            XCTAssertFalse(like.liked)
            XCTAssertEqual(like.likeCount, 0)
        })
    }

    func testToggleLike_nonexistentItem_returnsNotFound() async throws {
        let user = try await app.registerUser(email: "likemiss@test.com", password: "password123")

        try await app.test(.POST, "v1/feed/\(UUID().uuidString)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testToggleLike_invalidItemId_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badlike@test.com", password: "password123")

        try await app.test(.POST, "v1/feed/not-a-uuid/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testToggleLike_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/feed/\(UUID().uuidString)/like", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testToggleLike_multipleLikers_countsCorrectly() async throws {
        let user1 = try await app.registerUser(email: "ml1@test.com", password: "password123")
        let user2 = try await app.registerUser(email: "ml2@test.com", password: "password123")
        try await app.createAthleteProfile(token: user1.accessToken!, firstName: "Alice", lastName: "R")
        try await app.createAthleteProfile(token: user2.accessToken!, firstName: "Bob", lastName: "R")
        let user2Id = try await app.getUserId(email: "ml2@test.com")

        // Establish friendship so user2 can see the feed item
        try await app.establishFriendship(
            requestorToken: user1.accessToken!,
            recipientToken: user2.accessToken!,
            recipientUserId: user2Id
        )

        // User1 publishes
        var itemId: String?
        try await app.test(.POST, "v1/feed", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
            try req.content.encode(validActivityBody())
        }, afterResponse: { res in
            itemId = try res.content.decode(ActivityFeedItemResponse.self).id
        })

        // Both users like it
        try await app.test(.POST, "v1/feed/\(itemId!)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user1.accessToken!)
        }, afterResponse: { _ in })

        try await app.test(.POST, "v1/feed/\(itemId!)/like", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user2.accessToken!)
        }, afterResponse: { res in
            let like = try res.content.decode(LikeResponse.self)
            XCTAssertTrue(like.liked)
            XCTAssertEqual(like.likeCount, 2)
        })
    }
}
