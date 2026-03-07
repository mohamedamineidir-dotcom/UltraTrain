import Fluent

struct AddReferralToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("referral_code", .string)
            .field("referred_by_user_id", .uuid, .references("users", "id", onDelete: .setNull))
            .update()

        // Generate referral codes for existing users
        let users = try await UserModel.query(on: database).all()
        for user in users {
            user.referralCode = UserModel.generateReferralCode()
            try await user.save(on: database)
        }

        // Now add unique constraint and NOT NULL
        try await database.schema("users")
            .unique(on: "referral_code")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("referral_code")
            .deleteField("referred_by_user_id")
            .update()
    }
}
