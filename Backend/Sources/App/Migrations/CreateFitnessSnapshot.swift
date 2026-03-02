import Fluent

struct CreateFitnessSnapshot: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("fitness_snapshots")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("snapshot_id", .string, .required)
            .field("date", .datetime, .required)
            .field("fitness", .double, .required)
            .field("fatigue", .double, .required)
            .field("form", .double, .required)
            .field("fitness_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "snapshot_id", "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("fitness_snapshots").delete()
    }
}
