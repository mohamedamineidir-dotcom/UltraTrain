import Fluent

struct CreateGroupChallenge: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("group_challenges")
            .id()
            .field("creator_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("description_text", .string, .required)
            .field("type", .string, .required)
            .field("target_value", .double, .required)
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .field("status", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "idempotency_key", "creator_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("group_challenges").delete()
    }
}
