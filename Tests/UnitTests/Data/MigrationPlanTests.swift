import Testing
import SwiftData
@testable import UltraTrain

struct MigrationPlanTests {

    @Test func schemaV1Has36Models() {
        #expect(SchemaV1.models.count == 36)
    }

    @Test func schemaV1VersionIsCorrect() {
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test func migrationPlanHasSchemaV1() {
        #expect(UltraTrainMigrationPlan.schemas.count == 1)
    }

    @Test func migrationPlanHasNoStages() {
        #expect(UltraTrainMigrationPlan.stages.isEmpty)
    }

    @Test func modelContainerCreatesWithMigrationPlan() throws {
        let schema = Schema(SchemaV1.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: UltraTrainMigrationPlan.self,
            configurations: config
        )
        #expect(container.schema.entities.count > 0)
    }
}
