import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRacePrepChecklistRepository Tests")
@MainActor
struct LocalRacePrepChecklistRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            RacePrepChecklistSwiftDataModel.self,
            ChecklistItemSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeChecklist(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        items: [ChecklistItem] = []
    ) -> RacePrepChecklist {
        RacePrepChecklist(
            id: id,
            raceId: raceId,
            items: items.isEmpty ? [
                ChecklistItem(
                    id: UUID(),
                    name: "Headlamp",
                    category: .gear,
                    isChecked: false,
                    isCustom: false
                ),
                ChecklistItem(
                    id: UUID(),
                    name: "Energy gels",
                    category: .nutrition,
                    isChecked: true,
                    isCustom: false
                )
            ] : items,
            createdAt: Date(),
            lastModified: Date()
        )
    }

    @Test("Save and get checklist for race")
    func saveAndGetChecklistForRace() async throws {
        let container = try makeContainer()
        let repo = LocalRacePrepChecklistRepository(modelContainer: container)
        let raceId = UUID()

        try await repo.saveChecklist(makeChecklist(raceId: raceId))

        let fetched = try await repo.getChecklist(for: raceId)
        #expect(fetched != nil)
        #expect(fetched?.raceId == raceId)
        #expect(fetched?.items.count == 2)
    }

    @Test("Get checklist returns nil for unknown race")
    func getChecklistReturnsNilForUnknownRace() async throws {
        let container = try makeContainer()
        let repo = LocalRacePrepChecklistRepository(modelContainer: container)

        let fetched = try await repo.getChecklist(for: UUID())
        #expect(fetched == nil)
    }

    @Test("Save checklist replaces existing for same race")
    func saveChecklistReplacesExistingForSameRace() async throws {
        let container = try makeContainer()
        let repo = LocalRacePrepChecklistRepository(modelContainer: container)
        let raceId = UUID()

        let original = makeChecklist(raceId: raceId, items: [
            ChecklistItem(id: UUID(), name: "Item 1", category: .gear, isChecked: false, isCustom: false)
        ])
        try await repo.saveChecklist(original)

        let replacement = makeChecklist(raceId: raceId, items: [
            ChecklistItem(id: UUID(), name: "Item A", category: .nutrition, isChecked: true, isCustom: false),
            ChecklistItem(id: UUID(), name: "Item B", category: .safety, isChecked: false, isCustom: true)
        ])
        try await repo.saveChecklist(replacement)

        let fetched = try await repo.getChecklist(for: raceId)
        #expect(fetched?.items.count == 2)
    }

    @Test("Delete checklist removes it")
    func deleteChecklistRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalRacePrepChecklistRepository(modelContainer: container)
        let raceId = UUID()

        try await repo.saveChecklist(makeChecklist(raceId: raceId))
        try await repo.deleteChecklist(for: raceId)

        let fetched = try await repo.getChecklist(for: raceId)
        #expect(fetched == nil)
    }

    @Test("Delete checklist for unknown race does not throw")
    func deleteChecklistForUnknownRaceDoesNotThrow() async throws {
        let container = try makeContainer()
        let repo = LocalRacePrepChecklistRepository(modelContainer: container)

        try await repo.deleteChecklist(for: UUID())
        // Should not throw
    }
}
