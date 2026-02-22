import Foundation

protocol RouteRepository: Sendable {
    func getRoutes() async throws -> [SavedRoute]
    func getRoute(id: UUID) async throws -> SavedRoute?
    func saveRoute(_ route: SavedRoute) async throws
    func updateRoute(_ route: SavedRoute) async throws
    func deleteRoute(id: UUID) async throws
}
