import Foundation
@testable import UltraTrain

final class MockGearRepository: GearRepository, @unchecked Sendable {
    var items: [GearItem] = []
    var savedItem: GearItem?
    var updatedItem: GearItem?
    var deletedId: UUID?
    var updatedMileageGearIds: [UUID]?
    var updatedMileageDistance: Double?
    var updatedMileageDuration: TimeInterval?
    var shouldThrow = false

    func getGearItems() async throws -> [GearItem] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return items
    }

    func getGearItem(id: UUID) async throws -> GearItem? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return items.first { $0.id == id }
    }

    func getActiveGear(ofType type: GearType?) async throws -> [GearItem] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        let active = items.filter { !$0.isRetired }
        if let type {
            return active.filter { $0.type == type }
        }
        return active
    }

    func saveGearItem(_ item: GearItem) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedItem = item
        items.append(item)
    }

    func updateGearItem(_ item: GearItem) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updatedItem = item
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    func deleteGearItem(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deletedId = id
        items.removeAll { $0.id == id }
    }

    func updateGearMileage(gearIds: [UUID], distanceKm: Double, duration: TimeInterval) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updatedMileageGearIds = gearIds
        updatedMileageDistance = distanceKm
        updatedMileageDuration = duration
        for gearId in gearIds {
            if let index = items.firstIndex(where: { $0.id == gearId }) {
                items[index].totalDistanceKm += distanceKm
                items[index].totalDuration += duration
            }
        }
    }
}
