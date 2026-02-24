import Fluent

struct CreateChallengeParticipant: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("challenge_participants")
            .id()
            .field("challenge_id", .uuid, .required, .references("group_challenges", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("display_name", .string, .required)
            .field("current_value", .double, .required, .sql(.default(0)))
            .field("joined_date", .datetime, .required)
            .field("updated_at", .datetime)
            .unique(on: "challenge_id", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("challenge_participants").delete()
    }
}
