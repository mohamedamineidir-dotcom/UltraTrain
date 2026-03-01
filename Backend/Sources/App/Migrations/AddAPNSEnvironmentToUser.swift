import Fluent

struct AddAPNSEnvironmentToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("apns_environment", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("apns_environment")
            .update()
    }
}
