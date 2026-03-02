import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRouteRepository Tests")
@MainActor
struct LocalRouteRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([SavedRouteSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRoute(
        id: UUID = UUID(),
        name: String = "UTMB Course",
        distanceKm: Double = 171.0,
        elevationGainM: Double = 10000,
        elevationLossM: Double = 10000,
        source: RouteSource = .gpxImport,
        createdAt: Date = Date(),
        notes: String? = nil
    ) -> SavedRoute {
        SavedRoute(
            id: id,
            name: name,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            trackPoints: [],
            courseRoute: [],
            checkpoints: [],
            source: source,
            createdAt: createdAt,
            notes: notes
        )
    }

    // MARK: - Save & Fetch

    @Test("Save route and fetch all routes returns the saved route")
    func saveAndFetchRoutes() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)
        let route = makeRoute(name: "CCC Route")

        try await repo.saveRoute(route)
        let routes = try await repo.getRoutes()

        #expect(routes.count == 1)
        #expect(routes.first?.name == "CCC Route")
        #expect(routes.first?.distanceKm == 171.0)
    }

    @Test("Fetch route by ID returns the correct route")
    func fetchRouteById() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)
        let routeId = UUID()
        let route = makeRoute(id: routeId, name: "TDS Route")

        try await repo.saveRoute(route)
        let fetched = try await repo.getRoute(id: routeId)

        #expect(fetched != nil)
        #expect(fetched?.id == routeId)
        #expect(fetched?.name == "TDS Route")
    }

    @Test("Fetch route by unknown ID returns nil")
    func fetchRouteByUnknownIdReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)

        let fetched = try await repo.getRoute(id: UUID())
        #expect(fetched == nil)
    }

    @Test("Get routes returns empty when no routes saved")
    func getRoutesReturnsEmptyWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)

        let routes = try await repo.getRoutes()
        #expect(routes.isEmpty)
    }

    // MARK: - Update

    @Test("Update route modifies stored fields")
    func updateRouteModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)
        let routeId = UUID()

        let original = makeRoute(id: routeId, name: "Original Name", distanceKm: 100)
        try await repo.saveRoute(original)

        let updated = SavedRoute(
            id: routeId,
            name: "Updated Name",
            distanceKm: 120,
            elevationGainM: 5000,
            elevationLossM: 5000,
            trackPoints: [],
            courseRoute: [],
            checkpoints: [],
            source: .gpxImport,
            createdAt: original.createdAt,
            notes: "Updated notes"
        )
        try await repo.updateRoute(updated)

        let fetched = try await repo.getRoute(id: routeId)
        #expect(fetched?.name == "Updated Name")
        #expect(fetched?.distanceKm == 120)
        #expect(fetched?.notes == "Updated notes")
    }

    @Test("Update nonexistent route throws routeNotFound")
    func updateNonexistentRouteThrows() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)
        let route = makeRoute()

        do {
            try await repo.updateRoute(route)
            Issue.record("Expected DomainError.routeNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .routeNotFound)
        }
    }

    // MARK: - Delete

    @Test("Delete route removes it from storage")
    func deleteRouteRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)
        let routeId = UUID()
        let route = makeRoute(id: routeId)

        try await repo.saveRoute(route)
        try await repo.deleteRoute(id: routeId)

        let fetched = try await repo.getRoute(id: routeId)
        #expect(fetched == nil)
    }

    @Test("Delete nonexistent route does not throw")
    func deleteNonexistentRouteDoesNotThrow() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)

        try await repo.deleteRoute(id: UUID())
        // Should not throw -- the implementation silently returns if not found
    }

    // MARK: - Route Source Round-trip

    @Test("Route source preserved through round-trip")
    func routeSourcePreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)

        let route = makeRoute(source: .completedRun)
        try await repo.saveRoute(route)

        let fetched = try await repo.getRoute(id: route.id)
        #expect(fetched?.source == .completedRun)
    }

    @Test("Multiple routes returned sorted by createdAt descending")
    func multipleRoutesSortedByCreatedAt() async throws {
        let container = try makeContainer()
        let repo = LocalRouteRepository(modelContainer: container)

        let older = makeRoute(
            name: "Older Route",
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        )
        let newer = makeRoute(
            name: "Newer Route",
            createdAt: Date()
        )
        try await repo.saveRoute(older)
        try await repo.saveRoute(newer)

        let routes = try await repo.getRoutes()
        #expect(routes.count == 2)
        #expect(routes[0].name == "Newer Route")
        #expect(routes[1].name == "Older Route")
    }
}
