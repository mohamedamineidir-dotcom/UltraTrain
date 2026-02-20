import Foundation
import os

@Observable
@MainActor
final class RacePrepChecklistViewModel {
    private let race: Race
    private let repository: any RacePrepChecklistRepository

    var checklist: RacePrepChecklist?
    var isLoading = false
    var error: String?
    var showAddItem = false

    init(race: Race, repository: any RacePrepChecklistRepository) {
        self.race = race
        self.repository = repository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let existing = try await repository.getChecklist(for: race.id) {
                checklist = existing
            } else {
                let items = DefaultChecklistGenerator.generate(for: race)
                let newChecklist = RacePrepChecklist(
                    id: UUID(),
                    raceId: race.id,
                    items: items,
                    createdAt: .now,
                    lastModified: .now
                )
                try await repository.saveChecklist(newChecklist)
                checklist = newChecklist
            }
        } catch {
            Logger.checklist.error("Failed to load checklist: \(error.localizedDescription)")
            self.error = "Failed to load checklist."
        }
    }

    // MARK: - Toggle

    func toggleItem(_ itemId: UUID) async {
        guard var current = checklist,
              let index = current.items.firstIndex(where: { $0.id == itemId }) else { return }

        current.items[index].isChecked.toggle()
        current.lastModified = .now
        checklist = current

        do {
            try await repository.saveChecklist(current)
        } catch {
            Logger.checklist.error("Failed to save checklist: \(error.localizedDescription)")
            self.error = "Failed to save changes."
        }
    }

    // MARK: - Add

    func addItem(name: String, category: ChecklistCategory, notes: String?) async {
        guard var current = checklist else { return }

        let item = ChecklistItem(
            id: UUID(),
            name: name,
            category: category,
            isChecked: false,
            isCustom: true,
            notes: notes
        )
        current.items.append(item)
        current.lastModified = .now
        checklist = current

        do {
            try await repository.saveChecklist(current)
        } catch {
            Logger.checklist.error("Failed to add item: \(error.localizedDescription)")
            self.error = "Failed to add item."
        }
    }

    // MARK: - Delete

    func deleteItem(_ itemId: UUID) async {
        guard var current = checklist else { return }

        current.items.removeAll { $0.id == itemId }
        current.lastModified = .now
        checklist = current

        do {
            try await repository.saveChecklist(current)
        } catch {
            Logger.checklist.error("Failed to delete item: \(error.localizedDescription)")
            self.error = "Failed to delete item."
        }
    }

    // MARK: - Reset

    func resetChecklist() async {
        let items = DefaultChecklistGenerator.generate(for: race)
        let newChecklist = RacePrepChecklist(
            id: checklist?.id ?? UUID(),
            raceId: race.id,
            items: items,
            createdAt: checklist?.createdAt ?? .now,
            lastModified: .now
        )

        do {
            try await repository.saveChecklist(newChecklist)
            checklist = newChecklist
        } catch {
            Logger.checklist.error("Failed to reset checklist: \(error.localizedDescription)")
            self.error = "Failed to reset checklist."
        }
    }

    // MARK: - Computed

    var groupedItems: [(category: ChecklistCategory, items: [ChecklistItem])] {
        guard let checklist else { return [] }
        return ChecklistCategory.allCases.compactMap { category in
            let items = checklist.items.filter { $0.category == category }
            return items.isEmpty ? nil : (category: category, items: items)
        }
    }

    var totalProgress: (checked: Int, total: Int) {
        guard let checklist else { return (0, 0) }
        let checked = checklist.items.filter(\.isChecked).count
        return (checked, checklist.items.count)
    }
}
