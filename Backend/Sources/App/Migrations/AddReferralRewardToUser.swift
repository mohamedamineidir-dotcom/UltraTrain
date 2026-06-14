import Fluent
import SQLKit
import Vapor

/// Adds the referral-reward columns: a server-granted free-premium window
/// (`referral_bonus_until`) and a one-time claim marker
/// (`referral_reward_claimed_at`).
struct AddReferralRewardToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database must support SQL")
        }
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_bonus_until TIMESTAMPTZ").run()
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_reward_claimed_at TIMESTAMPTZ").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("referral_bonus_until")
            .deleteField("referral_reward_claimed_at")
            .update()
    }
}
