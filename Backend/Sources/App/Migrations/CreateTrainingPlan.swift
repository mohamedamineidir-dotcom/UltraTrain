import Fluent

struct CreateTrainingPlan: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("training_plans")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("target_race_name", .string, .required)
            .field("target_race_date", .datetime, .required)
            .field("total_weeks", .int, .required)
            .field("plan_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("training_plans").delete()
    }
}
