import Fluent

struct CreateFriendConnection: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("friend_connections")
            .id()
            .field("requestor_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipient_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("accepted_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "requestor_id", "recipient_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("friend_connections").delete()
    }
}
