import Fluent

struct CreateFinishEstimate: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("finish_estimates")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("estimate_id", .string, .required)
            .field("race_id", .string, .required)
            .field("expected_time", .double, .required)
            .field("confidence_percent", .double, .required)
            .field("estimate_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "estimate_id", "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("finish_estimates").delete()
    }
}
