import Fluent

struct CreateAnalyticsEvent: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("analytics_events")
            .id()
            .field("name", .string, .required)
            .field("properties_json", .string)
            .field("event_timestamp", .datetime, .required)
            .field("app_version", .string, .required)
            .field("build_number", .string, .required)
            .field("platform", .string, .required)
            .field("locale", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("analytics_events").delete()
    }
}
