import Fluent
import SQLKit
import Vapor

struct AddNameToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database must support SQL")
        }

        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT").run()
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
