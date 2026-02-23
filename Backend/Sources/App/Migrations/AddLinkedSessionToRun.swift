import Fluent

struct AddLinkedSessionToRun: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("runs")
            .field("linked_session_id", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("runs")
            .deleteField("linked_session_id")
            .update()
    }
}
