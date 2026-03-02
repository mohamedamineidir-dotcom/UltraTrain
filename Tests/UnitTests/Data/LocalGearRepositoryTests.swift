import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalGearRepository Tests")
@MainActor
struct LocalGearRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([GearItemSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeGear(
        id: UUID = UUID(),
        name: String = "Trail Shoes",
        type: GearType = .trailShoes,
        isRetired: Bool = false,
        totalDistanceKm: Double = 0
    ) -> GearItem {
        GearItem(
            id: id,
            name: name,
            brand: "Salomon",
            type: type,
            purchaseDate: .now,
            maxDistanceKm: 800,
            totalDistanceKm: totalDistanceKm,
            totalDuration: 0,
            isRetired: isRetired,
            notes: nil
        )
    }

    @Test("Save and retrieve gear item")
    func saveAndRetrieve() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        let gear = makeGear()

        try await repo.saveGearItem(gear)
        let items = try await repo.getGearItems()

        #expect(items.count == 1)
        #expect(items.first?.name == "Trail Shoes")
        #expect(items.first?.brand == "Salomon")
    }

    @Test("Get gear item by ID")
    func getById() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        let gear = makeGear()

        try await repo.saveGearItem(gear)
        let retrieved = try await repo.getGearItem(id: gear.id)

        #expect(retrieved != nil)
        #expect(retrieved?.id == gear.id)
    }

    @Test("Get gear item by ID returns nil when not found")
    func getByIdReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        let result = try await repo.getGearItem(id: UUID())
        #expect(result == nil)
    }

    @Test("Get active gear excludes retired items")
    func activeGearExcludesRetired() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)

        try await repo.saveGearItem(makeGear(name: "Active Shoes", isRetired: false))
        try await repo.saveGearItem(makeGear(name: "Old Shoes", isRetired: true))

        let active = try await repo.getActiveGear(ofType: nil)
        #expect(active.count == 1)
        #expect(active.first?.name == "Active Shoes")
    }

    @Test("Get active gear filters by type")
    func activeGearFiltersByType() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)

        try await repo.saveGearItem(makeGear(name: "Shoes", type: .trailShoes))
        try await repo.saveGearItem(makeGear(name: "Watch", type: .headlamp))

        let shoes = try await repo.getActiveGear(ofType: .trailShoes)
        #expect(shoes.count == 1)
        #expect(shoes.first?.name == "Shoes")
    }

    @Test("Update gear item modifies fields")
    func updateGearItem() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        var gear = makeGear()

        try await repo.saveGearItem(gear)
        gear.name = "Updated Shoes"
        gear.isRetired = true
        try await repo.updateGearItem(gear)

        let retrieved = try await repo.getGearItem(id: gear.id)
        #expect(retrieved?.name == "Updated Shoes")
        #expect(retrieved?.isRetired == true)
    }

    @Test("Delete gear item removes it")
    func deleteGearItem() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        let gear = makeGear()

        try await repo.saveGearItem(gear)
        try await repo.deleteGearItem(id: gear.id)

        let items = try await repo.getGearItems()
        #expect(items.isEmpty)
    }

    @Test("Delete nonexistent gear throws error")
    func deleteNonexistentThrows() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)

        await #expect(throws: (any Error).self) {
            try await repo.deleteGearItem(id: UUID())
        }
    }

    @Test("Update gear mileage adds distance and duration")
    func updateMileage() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        let gear = makeGear(totalDistanceKm: 100)

        try await repo.saveGearItem(gear)
        try await repo.updateGearMileage(gearIds: [gear.id], distanceKm: 15, duration: 5400)

        let retrieved = try await repo.getGearItem(id: gear.id)
        #expect(retrieved?.totalDistanceKm == 115)
        #expect(retrieved?.totalDuration == 5400)
    }

    @Test("Update mileage with empty gear IDs does nothing")
    func updateMileageEmptyIds() async throws {
        let container = try makeContainer()
        let repo = LocalGearRepository(modelContainer: container)
        try await repo.updateGearMileage(gearIds: [], distanceKm: 10, duration: 3600)
        // No throw = success
    }
}
