import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalNutritionRepository Tests")
@MainActor
struct LocalNutritionRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            NutritionPlanSwiftDataModel.self,
            NutritionEntrySwiftDataModel.self,
            NutritionProductSwiftDataModel.self,
            NutritionPreferencesSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeProduct(
        id: UUID = UUID(),
        name: String = "Maurten Gel 100",
        type: ProductType = .gel,
        caloriesPerServing: Int = 100,
        carbsGramsPerServing: Double = 25,
        sodiumMgPerServing: Int = 30,
        caffeinated: Bool = false
    ) -> NutritionProduct {
        NutritionProduct(
            id: id,
            name: name,
            type: type,
            caloriesPerServing: caloriesPerServing,
            carbsGramsPerServing: carbsGramsPerServing,
            sodiumMgPerServing: sodiumMgPerServing,
            caffeineMgPerServing: caffeinated ? 25 : 0
        )
    }

    private func makeEntry(
        product: NutritionProduct? = nil,
        timingMinutes: Int = 30,
        quantity: Int = 1
    ) -> NutritionEntry {
        let prod = product ?? makeProduct()
        return NutritionEntry(
            id: UUID(),
            product: prod,
            timingMinutes: timingMinutes,
            quantity: quantity,
            notes: nil
        )
    }

    private func makePlan(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        caloriesPerHour: Int = 250,
        hydrationMlPerHour: Int = 500,
        sodiumMgPerHour: Int = 600,
        entries: [NutritionEntry]? = nil
    ) -> NutritionPlan {
        NutritionPlan(
            id: id,
            raceId: raceId,
            carbsPerHour: caloriesPerHour / 4,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: hydrationMlPerHour,
            sodiumMgPerHour: sodiumMgPerHour,
            totalCaffeineMg: 0,
            entries: entries ?? [makeEntry()],
            gutTrainingSessionIds: []
        )
    }

    // MARK: - Save & Fetch Nutrition Plan

    @Test("Save nutrition plan and fetch by race ID")
    func saveAndFetchPlan() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)
        let raceId = UUID()
        let plan = makePlan(raceId: raceId)

        try await repo.saveNutritionPlan(plan)
        let fetched = try await repo.getNutritionPlan(for: raceId)

        #expect(fetched != nil)
        #expect(fetched?.raceId == raceId)
        #expect(fetched?.caloriesPerHour == 250)
        #expect(fetched?.hydrationMlPerHour == 500)
        #expect(fetched?.sodiumMgPerHour == 600)
    }

    @Test("Fetch nutrition plan returns nil when none exists")
    func fetchPlanReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)

        let fetched = try await repo.getNutritionPlan(for: UUID())
        #expect(fetched == nil)
    }

    @Test("Save nutrition plan replaces existing plan for same race")
    func savePlanReplacesExisting() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)
        let raceId = UUID()

        let plan1 = makePlan(raceId: raceId, caloriesPerHour: 200)
        try await repo.saveNutritionPlan(plan1)

        let plan2 = makePlan(raceId: raceId, caloriesPerHour: 300)
        try await repo.saveNutritionPlan(plan2)

        let fetched = try await repo.getNutritionPlan(for: raceId)
        #expect(fetched?.caloriesPerHour == 300)
    }

    // MARK: - Update Nutrition Plan

    @Test("Update nutrition plan modifies fields")
    func updatePlanModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)
        let planId = UUID()
        let raceId = UUID()

        let original = makePlan(id: planId, raceId: raceId, caloriesPerHour: 250)
        try await repo.saveNutritionPlan(original)

        let updated = NutritionPlan(
            id: planId,
            raceId: raceId,
            carbsPerHour: 87,
            caloriesPerHour: 350,
            hydrationMlPerHour: 700,
            sodiumMgPerHour: 800,
            totalCaffeineMg: 0,
            entries: [],
            gutTrainingSessionIds: []
        )
        try await repo.updateNutritionPlan(updated)

        let fetched = try await repo.getNutritionPlan(for: raceId)
        #expect(fetched?.caloriesPerHour == 350)
        #expect(fetched?.hydrationMlPerHour == 700)
    }

    @Test("Update nonexistent plan throws nutritionPlanNotFound")
    func updateNonexistentPlanThrows() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)
        let plan = makePlan()

        do {
            try await repo.updateNutritionPlan(plan)
            Issue.record("Expected DomainError.nutritionPlanNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .nutritionPlanNotFound)
        }
    }

    // MARK: - Products

    @Test("Save and fetch products")
    func saveAndFetchProducts() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)
        let product = makeProduct(name: "Tailwind")

        try await repo.saveProduct(product)
        let products = try await repo.getProducts()

        #expect(products.count == 1)
        #expect(products.first?.name == "Tailwind")
    }

    @Test("Products are returned sorted by name")
    func productsSortedByName() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)

        try await repo.saveProduct(makeProduct(name: "Ztailwind"))
        try await repo.saveProduct(makeProduct(name: "Atailwind"))

        let products = try await repo.getProducts()
        #expect(products.count == 2)
        #expect(products[0].name == "Atailwind")
        #expect(products[1].name == "Ztailwind")
    }

    // MARK: - Preferences

    @Test("Default preferences returned when none saved")
    func defaultPreferencesWhenNoneSaved() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)

        let prefs = try await repo.getNutritionPreferences()
        #expect(prefs == .default)
    }

    @Test("Save and fetch custom preferences")
    func saveAndFetchPreferences() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)

        var prefs = NutritionPreferences.default
        prefs.avoidCaffeine = true
        prefs.preferRealFood = true
        try await repo.saveNutritionPreferences(prefs)

        let fetched = try await repo.getNutritionPreferences()
        #expect(fetched.avoidCaffeine == true)
        #expect(fetched.preferRealFood == true)
    }

    @Test("Save preferences replaces existing preferences")
    func savePreferencesReplacesExisting() async throws {
        let container = try makeContainer()
        let repo = LocalNutritionRepository(modelContainer: container)

        let prefs1 = NutritionPreferences.default
        try await repo.saveNutritionPreferences(prefs1)

        var prefs2 = NutritionPreferences.default
        prefs2.avoidCaffeine = true
        prefs2.preferRealFood = true
        try await repo.saveNutritionPreferences(prefs2)

        let fetched = try await repo.getNutritionPreferences()
        #expect(fetched.avoidCaffeine == true)
        #expect(fetched.preferRealFood == true)
    }
}
