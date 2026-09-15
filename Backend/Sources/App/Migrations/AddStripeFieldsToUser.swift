import Fluent
import SQLKit
import Vapor

/// Adds Stripe billing fields for the website checkout flow: the linked
/// Stripe customer/subscription IDs, and a server-granted premium window
/// (`web_premium_until`) mirroring the existing referral-bonus pattern.
struct AddStripeFieldsToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database must support SQL")
        }
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT").run()
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT").run()
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS web_premium_until TIMESTAMPTZ").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("stripe_customer_id")
            .deleteField("stripe_subscription_id")
            .deleteField("web_premium_until")
            .update()
    }
}
