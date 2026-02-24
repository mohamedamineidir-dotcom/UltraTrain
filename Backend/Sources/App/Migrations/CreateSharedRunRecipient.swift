import Fluent

struct CreateSharedRunRecipient: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("shared_run_recipients")
            .id()
            .field("shared_run_id", .uuid, .required, .references("shared_runs", "id", onDelete: .cascade))
            .field("recipient_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "shared_run_id", "recipient_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("shared_run_recipients").delete()
    }
}
