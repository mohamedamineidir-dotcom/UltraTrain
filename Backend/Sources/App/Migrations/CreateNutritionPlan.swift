import Fluent

struct CreateNutritionPlan: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("nutrition_plans")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("nutrition_plan_id", .string, .required)
            .field("race_id", .string, .required)
            .field("calories_per_hour", .int, .required)
            .field("nutrition_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "nutrition_plan_id", "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("nutrition_plans").delete()
    }
}
