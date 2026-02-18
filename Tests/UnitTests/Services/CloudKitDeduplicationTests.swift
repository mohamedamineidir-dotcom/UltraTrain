import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("CloudKit Deduplication Tests")
struct CloudKitDeduplicationTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            AthleteSwiftDataModel.self,
            RaceSwiftDataModel.self,
            CheckpointSwiftDataModel.self,
            TrainingPlanSwiftDataModel.self,
            TrainingWeekSwiftDataModel.self,
            TrainingSessionSwiftDataModel.self,
            NutritionPlanSwiftDataModel.self,
            NutritionEntrySwiftDataModel.self,
            NutritionProductSwiftDataModel.self,
            CompletedRunSwiftDataModel.self,
            SplitSwiftDataModel.self,
            FitnessSnapshotSwiftDataModel.self,
            AppSettingsSwiftDataModel.self,
            NutritionPreferencesSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("Deduplicates singleton models keeping most recent")
    func deduplicateSingletonModels() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let older = AthleteSwiftDataModel()
        older.firstName = "Old"
        older.updatedAt = Date(timeIntervalSinceNow: -3600)

        let newer = AthleteSwiftDataModel()
        newer.firstName = "New"
        newer.updatedAt = Date()

        context.insert(older)
        context.insert(newer)
        try context.save()

        await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)

        let verifyContext = ModelContext(container)
        let remaining = try verifyContext.fetch(FetchDescriptor<AthleteSwiftDataModel>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.firstName == "New")
    }

    @Test("Deduplicates entity models by ID keeping most recent")
    func deduplicateEntityModels() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let sharedId = UUID()

        let older = NutritionProductSwiftDataModel()
        older.id = sharedId
        older.name = "Old Gel"
        older.updatedAt = Date(timeIntervalSinceNow: -3600)

        let newer = NutritionProductSwiftDataModel()
        newer.id = sharedId
        newer.name = "New Gel"
        newer.updatedAt = Date()

        context.insert(older)
        context.insert(newer)
        try context.save()

        await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)

        let verifyContext = ModelContext(container)
        let remaining = try verifyContext.fetch(FetchDescriptor<NutritionProductSwiftDataModel>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "New Gel")
    }

    @Test("No changes when no duplicates exist")
    func noDuplicates() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let product = NutritionProductSwiftDataModel()
        product.name = "Solo Gel"
        context.insert(product)
        try context.save()

        await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)

        let verifyContext = ModelContext(container)
        let remaining = try verifyContext.fetch(FetchDescriptor<NutritionProductSwiftDataModel>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Solo Gel")
    }

    @Test("Handles empty database gracefully")
    func emptyDatabase() async throws {
        let container = try makeContainer()
        await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)

        let context = ModelContext(container)
        let athletes = try context.fetch(FetchDescriptor<AthleteSwiftDataModel>())
        #expect(athletes.isEmpty)
    }
}
