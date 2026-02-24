import Fluent

struct CreateFeedLike: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("feed_likes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("feed_item_id", .uuid, .required, .references("activity_feed_items", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "feed_item_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("feed_likes").delete()
    }
}
