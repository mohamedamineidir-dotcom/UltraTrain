import Fluent

struct CreateActivityFeedItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("activity_feed_items")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("activity_type", .string, .required)
            .field("title", .string, .required)
            .field("subtitle", .string)
            .field("stats_json", .string)
            .field("timestamp", .datetime, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("activity_feed_items").delete()
    }
}
