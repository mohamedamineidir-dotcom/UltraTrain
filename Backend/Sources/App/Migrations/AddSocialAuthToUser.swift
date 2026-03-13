import Fluent
import SQLKit
import Vapor

struct AddSocialAuthToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database must support SQL")
        }

        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_user_id TEXT").run()
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_user_id TEXT").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("apple_user_id")
            .deleteField("google_user_id")
            .update()
    }
}
