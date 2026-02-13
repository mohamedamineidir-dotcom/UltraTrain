import Foundation

protocol RaceRepository: Sendable {
    func getRaces() async throws -> [Race]
    func getRace(id: UUID) async throws -> Race?
    func saveRace(_ race: Race) async throws
    func updateRace(_ race: Race) async throws
    func deleteRace(id: UUID) async throws
}
