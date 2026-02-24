import Vapor
import Fluent

struct ActivityFeedController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.get("feed", use: getFeed)
        protected.post("feed", use: publishActivity)
        protected.post("feed", ":itemId", "like", use: toggleLike)
    }

    @Sendable
    func getFeed(req: Request) async throws -> [ActivityFeedItemResponse] {
        let userId = try req.userId
        let limit = req.query[Int.self, at: "limit"] ?? 50

        // Get accepted friend IDs
        let connections = try await FriendConnectionModel.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$requestor.$id == userId)
                group.filter(\.$recipient.$id == userId)
            }
            .filter(\.$status == "accepted")
            .all()

        var friendIds: [UUID] = [userId] // Include self
        for conn in connections {
            let friendId = conn.$requestor.id == userId ? conn.$recipient.id : conn.$requestor.id
            friendIds.append(friendId)
        }

        // Fetch feed items from friends + self
        let items = try await ActivityFeedItemModel.query(on: req.db)
            .filter(\.$user.$id ~~ friendIds)
            .sort(\.$timestamp, .descending)
            .range(..<limit)
            .all()

        // Build responses with like counts and display names
        var responses: [ActivityFeedItemResponse] = []
        for item in items {
            let likeCount = try await FeedLikeModel.query(on: req.db)
                .filter(\.$feedItem.$id == item.id!)
                .count()

            let isLikedByMe = try await FeedLikeModel.query(on: req.db)
                .filter(\.$feedItem.$id == item.id!)
                .filter(\.$user.$id == userId)
                .first() != nil

            let displayName = try await getDisplayName(userId: item.$user.id, on: req.db)

            // Decode stats
            var stats: ActivityStatsJSON?
            if let json = item.statsJSON, let data = json.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                stats = try? decoder.decode(ActivityStatsJSON.self, from: data)
            }

            let formatter = ISO8601DateFormatter()
            responses.append(ActivityFeedItemResponse(
                id: item.id?.uuidString ?? "",
                athleteProfileId: item.$user.id.uuidString,
                athleteDisplayName: displayName,
                activityType: item.activityType,
                title: item.title,
                subtitle: item.subtitle,
                distanceKm: stats?.distanceKm,
                elevationGainM: stats?.elevationGainM,
                duration: stats?.duration,
                averagePace: stats?.averagePace,
                timestamp: formatter.string(from: item.timestamp),
                likeCount: likeCount,
                isLikedByMe: isLikedByMe
            ))
        }

        return responses
    }

    @Sendable
    func publishActivity(req: Request) async throws -> Response {
        try PublishActivityRequest.validate(content: req)
        let body = try req.content.decode(PublishActivityRequest.self)
        let userId = try req.userId

        // Idempotency check
        let existing = try await ActivityFeedItemModel.query(on: req.db)
            .filter(\.$idempotencyKey == body.idempotencyKey)
            .filter(\.$user.$id == userId)
            .first()

        if let existingItem = existing {
            let displayName = try await getDisplayName(userId: userId, on: req.db)
            let likeCount = try await FeedLikeModel.query(on: req.db)
                .filter(\.$feedItem.$id == existingItem.id!)
                .count()
            let formatter = ISO8601DateFormatter()
            let response = ActivityFeedItemResponse(
                id: existingItem.id?.uuidString ?? "",
                athleteProfileId: userId.uuidString,
                athleteDisplayName: displayName,
                activityType: existingItem.activityType,
                title: existingItem.title,
                subtitle: existingItem.subtitle,
                distanceKm: nil, elevationGainM: nil, duration: nil, averagePace: nil,
                timestamp: formatter.string(from: existingItem.timestamp),
                likeCount: likeCount,
                isLikedByMe: false
            )
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let formatter = ISO8601DateFormatter()
        guard let timestamp = formatter.date(from: body.timestamp) else {
            throw Abort(.badRequest, reason: "Invalid timestamp format. Use ISO8601.")
        }

        // Encode stats as JSON
        var statsJSON: String?
        let stats = ActivityStatsJSON(
            distanceKm: body.distanceKm,
            elevationGainM: body.elevationGainM,
            duration: body.duration,
            averagePace: body.averagePace
        )
        if body.distanceKm != nil || body.elevationGainM != nil || body.duration != nil || body.averagePace != nil {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if let data = try? encoder.encode(stats) {
                statsJSON = String(data: data, encoding: .utf8)
            }
        }

        let item = ActivityFeedItemModel()
        item.$user.id = userId
        item.activityType = body.activityType
        item.title = body.title
        item.subtitle = body.subtitle
        item.statsJSON = statsJSON
        item.timestamp = timestamp
        item.idempotencyKey = body.idempotencyKey
        try await item.save(on: req.db)

        let displayName = try await getDisplayName(userId: userId, on: req.db)
        let response = ActivityFeedItemResponse(
            id: item.id?.uuidString ?? "",
            athleteProfileId: userId.uuidString,
            athleteDisplayName: displayName,
            activityType: item.activityType,
            title: item.title,
            subtitle: item.subtitle,
            distanceKm: body.distanceKm,
            elevationGainM: body.elevationGainM,
            duration: body.duration,
            averagePace: body.averagePace,
            timestamp: body.timestamp,
            likeCount: 0,
            isLikedByMe: false
        )
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func toggleLike(req: Request) async throws -> LikeResponse {
        let userId = try req.userId

        guard let itemIdStr = req.parameters.get("itemId"),
              let itemId = UUID(uuidString: itemIdStr) else {
            throw Abort(.badRequest, reason: "Invalid item ID")
        }

        // Verify item exists
        guard try await ActivityFeedItemModel.find(itemId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Feed item not found")
        }

        // Check if already liked
        let existingLike = try await FeedLikeModel.query(on: req.db)
            .filter(\.$feedItem.$id == itemId)
            .filter(\.$user.$id == userId)
            .first()

        let liked: Bool
        if let existing = existingLike {
            try await existing.delete(on: req.db)
            liked = false
        } else {
            let like = FeedLikeModel()
            like.$user.id = userId
            like.$feedItem.id = itemId
            try await like.save(on: req.db)
            liked = true
        }

        let likeCount = try await FeedLikeModel.query(on: req.db)
            .filter(\.$feedItem.$id == itemId)
            .count()

        return LikeResponse(liked: liked, likeCount: likeCount)
    }

    // MARK: - Helpers

    private func getDisplayName(userId: UUID, on db: Database) async throws -> String {
        if let athlete = try await AthleteModel.query(on: db)
            .filter(\.$user.$id == userId)
            .first() {
            return athlete.displayName.isEmpty ? "\(athlete.firstName) \(athlete.lastName)" : athlete.displayName
        }
        return "Unknown"
    }
}
