import Foundation
@testable import UltraTrain

final class MockRouteRepository: RouteRepository, @unchecked Sendable {
    var routes: [SavedRoute] = []
    var savedRoute: SavedRoute?
    var updatedRoute: SavedRoute?
    var deletedId: UUID?
    var shouldThrow = false

    func getRoutes() async throws -> [SavedRoute] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return routes
    }

    func getRoute(id: UUID) async throws -> SavedRoute? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return routes.first { $0.id == id }
    }

    func saveRoute(_ route: SavedRoute) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedRoute = route
        routes.append(route)
    }

    func updateRoute(_ route: SavedRoute) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updatedRoute = route
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        }
    }

    func deleteRoute(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deletedId = id
        routes.removeAll { $0.id == id }
    }
}
