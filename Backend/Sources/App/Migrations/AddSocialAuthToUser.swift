import Fluent

struct AddSocialAuthToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("apple_user_id", .string)
            .field("google_user_id", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("apple_user_id")
            .deleteField("google_user_id")
            .update()
    }
}
