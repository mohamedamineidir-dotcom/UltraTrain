import Fluent

struct AddEmailVerificationToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("is_email_verified", .bool, .required, .sql(.default(false)))
            .field("verification_code_hash", .string)
            .field("verification_code_expires_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("is_email_verified")
            .deleteField("verification_code_hash")
            .deleteField("verification_code_expires_at")
            .update()
    }
}
