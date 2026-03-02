import Fluent

struct CreateCrashReport: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("crash_reports")
            .id()
            .field("client_id", .uuid, .required)
            .field("timestamp", .datetime, .required)
            .field("error_type", .string, .required)
            .field("error_message", .string, .required)
            .field("stack_trace", .string, .required)
            .field("device_model", .string, .required)
            .field("os_version", .string, .required)
            .field("app_version", .string, .required)
            .field("build_number", .string, .required)
            .field("context_json", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("crash_reports").delete()
    }
}
