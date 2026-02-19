import Foundation

protocol GearRepository: Sendable {
    func getGearItems() async throws -> [GearItem]
    func getGearItem(id: UUID) async throws -> GearItem?
    func getActiveGear(ofType type: GearType?) async throws -> [GearItem]
    func saveGearItem(_ item: GearItem) async throws
    func updateGearItem(_ item: GearItem) async throws
    func deleteGearItem(id: UUID) async throws
    func updateGearMileage(gearIds: [UUID], distanceKm: Double, duration: TimeInterval) async throws
}
