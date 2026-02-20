import Foundation
import Testing
@testable import UltraTrain

@Suite("RacePrepChecklistViewModel Tests")
struct RacePrepChecklistViewModelTests {

    // MARK: - Helpers

    private func makeRace() -> Race {
        Race(
            id: UUID(),
            name: "UTMB",
            date: Date.now.adding(days: 30),
            distanceKm: 170,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [
                Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 30, elevationM: 1500, hasAidStation: true)
            ],
            terrainDifficulty: .technical
        )
    }

    private func makeChecklist(raceId: UUID) -> RacePrepChecklist {
        RacePrepChecklist(
            id: UUID(),
            raceId: raceId,
            items: [
                ChecklistItem(id: UUID(), name: "Trail shoes", category: .gear, isChecked: false, isCustom: false),
                ChecklistItem(id: UUID(), name: "Custom item", category: .gear, isChecked: false, isCustom: true)
            ],
            createdAt: .now,
            lastModified: .now
        )
    }

    // MARK: - Load

    @Test("Load creates default checklist when none exists")
    @MainActor
    func loadCreatesDefault() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let vm = RacePrepChecklistViewModel(race: race, repository: repo)

        await vm.load()

        #expect(vm.checklist != nil)
        #expect(vm.checklist?.raceId == race.id)
        #expect(vm.checklist?.items.isEmpty == false)
        #expect(repo.saveChecklistCalled)
    }

    @Test("Load returns existing checklist")
    @MainActor
    func loadExisting() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let existing = makeChecklist(raceId: race.id)
        repo.checklists[race.id] = existing

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        #expect(vm.checklist?.id == existing.id)
        #expect(vm.checklist?.items.count == 2)
    }

    // MARK: - Toggle

    @Test("Toggle item persists change")
    @MainActor
    func toggleItem() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let checklist = makeChecklist(raceId: race.id)
        let itemId = checklist.items[0].id
        repo.checklists[race.id] = checklist

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()
        await vm.toggleItem(itemId)

        #expect(vm.checklist?.items.first(where: { $0.id == itemId })?.isChecked == true)
        #expect(repo.saveChecklistCalled)
    }

    // MARK: - Add

    @Test("Add custom item appends to checklist")
    @MainActor
    func addItem() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let checklist = makeChecklist(raceId: race.id)
        repo.checklists[race.id] = checklist

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        let initialCount = vm.checklist?.items.count ?? 0
        await vm.addItem(name: "Power bank", category: .gear, notes: "Fully charged")

        #expect(vm.checklist?.items.count == initialCount + 1)
        let added = vm.checklist?.items.last
        #expect(added?.name == "Power bank")
        #expect(added?.isCustom == true)
        #expect(added?.notes == "Fully charged")
    }

    // MARK: - Delete

    @Test("Delete removes item from checklist")
    @MainActor
    func deleteItem() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let checklist = makeChecklist(raceId: race.id)
        let customItemId = checklist.items[1].id
        repo.checklists[race.id] = checklist

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()
        await vm.deleteItem(customItemId)

        #expect(vm.checklist?.items.contains(where: { $0.id == customItemId }) == false)
    }

    // MARK: - Reset

    @Test("Reset regenerates default items")
    @MainActor
    func resetChecklist() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        let checklist = makeChecklist(raceId: race.id)
        repo.checklists[race.id] = checklist

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        #expect(vm.checklist?.items.count == 2)

        await vm.resetChecklist()

        #expect(vm.checklist != nil)
        #expect((vm.checklist?.items.count ?? 0) > 2)
        #expect(vm.checklist?.items.allSatisfy { !$0.isCustom } == true)
    }

    // MARK: - Error Handling

    @Test("Load error sets error message")
    @MainActor
    func loadError() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        repo.shouldThrow = true

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.checklist == nil)
    }

    // MARK: - Grouped Items

    @Test("Grouped items organizes by category")
    @MainActor
    func groupedItems() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        let groups = vm.groupedItems
        #expect(!groups.isEmpty)

        for group in groups {
            #expect(group.items.allSatisfy { $0.category == group.category })
        }
    }

    // MARK: - Progress

    @Test("Total progress counts checked items")
    @MainActor
    func totalProgress() async {
        let race = makeRace()
        let repo = MockRacePrepChecklistRepository()
        var checklist = makeChecklist(raceId: race.id)
        checklist.items[0] = ChecklistItem(
            id: checklist.items[0].id,
            name: checklist.items[0].name,
            category: checklist.items[0].category,
            isChecked: true,
            isCustom: false
        )
        repo.checklists[race.id] = checklist

        let vm = RacePrepChecklistViewModel(race: race, repository: repo)
        await vm.load()

        let progress = vm.totalProgress
        #expect(progress.checked == 1)
        #expect(progress.total == 2)
    }
}
