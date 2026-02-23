import Fluent

struct AddPasswordResetToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("reset_code_hash", .string)
            .field("reset_code_expires_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("reset_code_hash")
            .deleteField("reset_code_expires_at")
            .update()
    }
}
