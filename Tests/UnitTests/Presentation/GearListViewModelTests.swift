import Foundation
import Testing
@testable import UltraTrain

@Suite("GearList ViewModel Tests")
struct GearListViewModelTests {

    private func makeGear(
        name: String = "Test Shoes",
        isRetired: Bool = false,
        totalDistanceKm: Double = 0
    ) -> GearItem {
        GearItem(
            id: UUID(),
            name: name,
            brand: "TestBrand",
            type: .trailShoes,
            purchaseDate: Date.now,
            maxDistanceKm: 800,
            totalDistanceKm: totalDistanceKm,
            totalDuration: 0,
            isRetired: isRetired,
            notes: nil
        )
    }

    @MainActor
    private func makeViewModel(
        repo: MockGearRepository = MockGearRepository()
    ) -> GearListViewModel {
        GearListViewModel(gearRepository: repo)
    }

    // MARK: - Load

    @Test("Load fetches gear items")
    @MainActor
    func loadFetchesGear() async {
        let repo = MockGearRepository()
        repo.items = [makeGear(name: "Shoe A"), makeGear(name: "Shoe B")]

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.gearItems.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles empty list")
    @MainActor
    func loadHandlesEmpty() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.gearItems.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("Load handles error")
    @MainActor
    func loadHandlesError() async {
        let repo = MockGearRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.gearItems.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Computed

    @Test("Active gear filters out retired items")
    @MainActor
    func activeGearFilters() {
        let vm = makeViewModel()
        vm.gearItems = [
            makeGear(name: "Active Shoe", isRetired: false),
            makeGear(name: "Retired Shoe", isRetired: true)
        ]

        #expect(vm.activeGear.count == 1)
        #expect(vm.activeGear.first?.name == "Active Shoe")
    }

    @Test("Retired gear filters out active items")
    @MainActor
    func retiredGearFilters() {
        let vm = makeViewModel()
        vm.gearItems = [
            makeGear(name: "Active Shoe", isRetired: false),
            makeGear(name: "Retired Shoe", isRetired: true)
        ]

        #expect(vm.retiredGear.count == 1)
        #expect(vm.retiredGear.first?.name == "Retired Shoe")
    }

    // MARK: - Add

    @Test("Add gear appends to list")
    @MainActor
    func addGear() async {
        let repo = MockGearRepository()
        let vm = makeViewModel(repo: repo)
        let gear = makeGear(name: "New Shoe")

        await vm.addGear(gear)

        #expect(vm.gearItems.count == 1)
        #expect(vm.gearItems.first?.name == "New Shoe")
        #expect(repo.savedItem?.name == "New Shoe")
        #expect(vm.error == nil)
    }

    @Test("Add gear handles error")
    @MainActor
    func addGearError() async {
        let repo = MockGearRepository()
        repo.shouldThrow = true
        let vm = makeViewModel(repo: repo)

        await vm.addGear(makeGear())

        #expect(vm.gearItems.isEmpty)
        #expect(vm.error != nil)
    }

    // MARK: - Update

    @Test("Update gear replaces in list")
    @MainActor
    func updateGear() async {
        let gear = makeGear(name: "Old Name")
        let repo = MockGearRepository()
        repo.items = [gear]

        let vm = makeViewModel(repo: repo)
        vm.gearItems = [gear]

        var updated = gear
        updated.name = "New Name"

        await vm.updateGear(updated)

        #expect(vm.gearItems.first?.name == "New Name")
        #expect(vm.error == nil)
    }

    @Test("Update gear handles error")
    @MainActor
    func updateGearError() async {
        let gear = makeGear()
        let repo = MockGearRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        vm.gearItems = [gear]

        var updated = gear
        updated.name = "Should Fail"

        await vm.updateGear(updated)

        #expect(vm.error != nil)
    }

    // MARK: - Retire

    @Test("Retire gear sets isRetired true")
    @MainActor
    func retireGear() async {
        let gear = makeGear(name: "Active Shoe")
        let repo = MockGearRepository()

        let vm = makeViewModel(repo: repo)
        vm.gearItems = [gear]

        await vm.retireGear(gear)

        #expect(vm.gearItems.first?.isRetired == true)
        #expect(vm.error == nil)
    }

    // MARK: - Delete

    @Test("Delete gear removes from list")
    @MainActor
    func deleteGear() async {
        let gear = makeGear()
        let repo = MockGearRepository()

        let vm = makeViewModel(repo: repo)
        vm.gearItems = [gear]

        await vm.deleteGear(id: gear.id)

        #expect(vm.gearItems.isEmpty)
        #expect(repo.deletedId == gear.id)
        #expect(vm.error == nil)
    }

    @Test("Delete gear handles error")
    @MainActor
    func deleteGearError() async {
        let gear = makeGear()
        let repo = MockGearRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        vm.gearItems = [gear]

        await vm.deleteGear(id: gear.id)

        #expect(vm.error != nil)
        #expect(vm.gearItems.count == 1)
    }
}
