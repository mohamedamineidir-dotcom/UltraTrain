import Fluent

struct CreateAthlete: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("athletes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("date_of_birth", .datetime, .required)
            .field("weight_kg", .double, .required)
            .field("height_cm", .double, .required)
            .field("resting_heart_rate", .int, .required)
            .field("max_heart_rate", .int, .required)
            .field("experience_level", .string, .required)
            .field("weekly_volume_km", .double, .required)
            .field("longest_run_km", .double, .required)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("athletes").delete()
    }
}
