import Fluent

struct AddSocialFieldsToAthlete: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("athletes")
            .field("bio", .string)
            .field("is_public_profile", .bool, .required, .sql(.default(true)))
            .field("display_name", .string, .required, .sql(.default("")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("athletes")
            .deleteField("bio")
            .deleteField("is_public_profile")
            .deleteField("display_name")
            .update()
    }
}
