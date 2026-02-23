import Fluent

struct AddUpdatedAtToRun: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("runs")
            .field("updated_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("runs")
            .deleteField("updated_at")
            .update()
    }
}
