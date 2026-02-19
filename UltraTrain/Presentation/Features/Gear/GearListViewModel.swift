import Foundation
import os

@Observable
@MainActor
final class GearListViewModel {

    // MARK: - Dependencies

    private let gearRepository: any GearRepository

    // MARK: - State

    var gearItems: [GearItem] = []
    var isLoading = false
    var error: String?
    var showingAddGear = false
    var gearToEdit: GearItem?
    var showingRetireConfirmation = false
    var gearToRetire: GearItem?

    // MARK: - Init

    init(gearRepository: any GearRepository) {
        self.gearRepository = gearRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            gearItems = try await gearRepository.getGearItems()
        } catch {
            self.error = error.localizedDescription
            Logger.gear.error("Failed to load gear: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed

    var activeGear: [GearItem] {
        gearItems.filter { !$0.isRetired }
    }

    var retiredGear: [GearItem] {
        gearItems.filter { $0.isRetired }
    }

    // MARK: - CRUD

    func addGear(_ item: GearItem) async {
        do {
            try await gearRepository.saveGearItem(item)
            gearItems.append(item)
        } catch {
            self.error = error.localizedDescription
            Logger.gear.error("Failed to add gear: \(error)")
        }
    }

    func updateGear(_ item: GearItem) async {
        do {
            try await gearRepository.updateGearItem(item)
            if let index = gearItems.firstIndex(where: { $0.id == item.id }) {
                gearItems[index] = item
            }
        } catch {
            self.error = error.localizedDescription
            Logger.gear.error("Failed to update gear: \(error)")
        }
    }

    func retireGear(_ item: GearItem) async {
        var retired = item
        retired.isRetired = true
        await updateGear(retired)
    }

    func deleteGear(id: UUID) async {
        do {
            try await gearRepository.deleteGearItem(id: id)
            gearItems.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
            Logger.gear.error("Failed to delete gear: \(error)")
        }
    }
}
