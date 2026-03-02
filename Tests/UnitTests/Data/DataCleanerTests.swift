import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("DataCleaner Tests")
@MainActor
struct DataCleanerTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            AthleteSwiftDataModel.self,
            RaceSwiftDataModel.self,
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
            GearItemSwiftDataModel.self,
            CheckpointSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("Execute clears athlete data")
    func executeClearsAthleteData() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let athlete = AthleteSwiftDataModel()
        athlete.id = UUID()
        athlete.firstName = "Kilian"
        athlete.lastName = "Jornet"
        context.insert(athlete)
        try context.save()

        let cleaner = DataCleaner(modelContainer: container)
        try await cleaner.execute()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<AthleteSwiftDataModel>()
        let count = try fetchContext.fetchCount(descriptor)
        #expect(count == 0)
    }

    @Test("Execute clears settings data")
    func executeClearsSettingsData() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let settings = AppSettingsSwiftDataModel()
        settings.id = UUID()
        context.insert(settings)
        try context.save()

        let cleaner = DataCleaner(modelContainer: container)
        try await cleaner.execute()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<AppSettingsSwiftDataModel>()
        let count = try fetchContext.fetchCount(descriptor)
        #expect(count == 0)
    }

    @Test("Execute clears fitness snapshot data")
    func executeClearsFitnessData() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let snapshot = FitnessSnapshotSwiftDataModel()
        snapshot.id = UUID()
        context.insert(snapshot)
        try context.save()

        let cleaner = DataCleaner(modelContainer: container)
        try await cleaner.execute()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<FitnessSnapshotSwiftDataModel>()
        let count = try fetchContext.fetchCount(descriptor)
        #expect(count == 0)
    }

    @Test("Execute succeeds on empty database")
    func executeSucceedsOnEmptyDatabase() async throws {
        let container = try makeContainer()
        let cleaner = DataCleaner(modelContainer: container)

        try await cleaner.execute()
        // Should not throw on empty database
    }

    @Test("Execute clears gear items")
    func executeClearsGearItems() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let gear = GearItemSwiftDataModel()
        gear.id = UUID()
        gear.name = "Trail Shoes"
        context.insert(gear)
        try context.save()

        let cleaner = DataCleaner(modelContainer: container)
        try await cleaner.execute()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<GearItemSwiftDataModel>()
        let count = try fetchContext.fetchCount(descriptor)
        #expect(count == 0)
    }
}
