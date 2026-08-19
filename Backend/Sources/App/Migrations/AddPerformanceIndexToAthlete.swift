import Fluent

struct AddPerformanceIndexToAthlete: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("athletes")
            .field("itra_index", .double)
            .field("itra_index_updated_at", .datetime)
            .field("previous_itra_index", .double)
            .field("previous_itra_index_updated_at", .datetime)
            .field("utmb_index", .double)
            .field("utmb_index_updated_at", .datetime)
            .field("previous_utmb_index", .double)
            .field("previous_utmb_index_updated_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("athletes")
            .deleteField("itra_index")
            .deleteField("itra_index_updated_at")
            .deleteField("previous_itra_index")
            .deleteField("previous_itra_index_updated_at")
            .deleteField("utmb_index")
            .deleteField("utmb_index_updated_at")
            .deleteField("previous_utmb_index")
            .deleteField("previous_utmb_index_updated_at")
            .update()
    }
}
