import Fluent

struct AddDeviceTokenToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("device_token", .string)
            .field("device_platform", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("device_token")
            .deleteField("device_platform")
            .update()
    }
}
