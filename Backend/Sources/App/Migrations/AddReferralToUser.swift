import Fluent
import SQLKit
import Vapor

struct AddReferralToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database must support SQL")
        }

        // Use IF NOT EXISTS to make migration idempotent
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT").run()
        try await sql.raw("""
            ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by_user_id UUID \
            REFERENCES users(id) ON DELETE SET NULL
            """).run()

        // Generate referral codes for existing users that don't have one (raw SQL to avoid ORM schema mismatch)
        let rows = try await sql.raw("SELECT id FROM users WHERE referral_code IS NULL").all()
        for row in rows {
            let code = UserModel.generateReferralCode()
            let id = try row.decode(column: "id", as: UUID.self)
            try await sql.raw("UPDATE users SET referral_code = \(bind: code) WHERE id = \(bind: id)").run()
        }

        // Add unique constraint if not already present
        try await sql.raw("""
            CREATE UNIQUE INDEX IF NOT EXISTS uq_users_referral_code ON users(referral_code)
            """).run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("referral_code")
            .deleteField("referred_by_user_id")
            .update()
    }
}
