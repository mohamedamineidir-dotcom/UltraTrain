import Fluent

struct CreateChallenge: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("challenges")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("description_text", .string, .required)
            .field("type", .string, .required)
            .field("target_value", .double, .required)
            .field("current_value", .double, .required, .sql(.default(0)))
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .field("status", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("challenges").delete()
    }
}
