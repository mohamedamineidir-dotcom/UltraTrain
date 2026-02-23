import Fluent

struct CreateRace: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("races")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("race_id", .string, .required)
            .field("name", .string, .required)
            .field("date", .datetime, .required)
            .field("distance_km", .double, .required)
            .field("elevation_gain_m", .double, .required)
            .field("priority", .string, .required)
            .field("race_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "race_id", "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("races").delete()
    }
}
