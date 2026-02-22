import Fluent

struct CreateRun: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("runs")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("date", .datetime, .required)
            .field("distance_km", .double, .required)
            .field("elevation_gain_m", .double, .required)
            .field("elevation_loss_m", .double, .required)
            .field("duration", .double, .required)
            .field("average_heart_rate", .int)
            .field("max_heart_rate", .int)
            .field("average_pace_seconds_per_km", .double, .required)
            .field("gps_track_json", .string, .required)
            .field("splits_json", .string, .required)
            .field("notes", .string)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("runs").delete()
    }
}
