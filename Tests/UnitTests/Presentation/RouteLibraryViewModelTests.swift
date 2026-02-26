import Testing
import Foundation
@testable import UltraTrain

@Suite("RouteLibraryViewModel Tests")
struct RouteLibraryViewModelTests {

    @MainActor
    private func makeViewModel(
        routeRepo: MockRouteRepository = MockRouteRepository(),
        runRepo: MockRunRepository = MockRunRepository()
    ) -> (RouteLibraryViewModel, MockRouteRepository, MockRunRepository) {
        let vm = RouteLibraryViewModel(
            routeRepository: routeRepo,
            runRepository: runRepo
        )
        return (vm, routeRepo, runRepo)
    }

    private func makeRoute(
        name: String = "Test Route",
        distanceKm: Double = 50
    ) -> SavedRoute {
        SavedRoute(
            id: UUID(),
            name: name,
            distanceKm: distanceKm,
            elevationGainM: 3000,
            elevationLossM: 2800,
            trackPoints: [],
            courseRoute: [],
            checkpoints: [],
            source: .gpxImport,
            createdAt: .now
        )
    }

    // MARK: - Initial State

    @Test("Initial state is empty")
    @MainActor
    func initialState() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.routes.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.searchText.isEmpty)
    }

    // MARK: - Load

    @Test("Load fetches routes from repository")
    @MainActor
    func loadFetchesRoutes() async {
        let routeRepo = MockRouteRepository()
        routeRepo.routes = [makeRoute(name: "UTMB"), makeRoute(name: "CCC")]
        let (vm, _, _) = makeViewModel(routeRepo: routeRepo)

        await vm.load()

        #expect(vm.routes.count == 2)
        #expect(vm.isLoading == false)
    }

    @Test("Load handles error")
    @MainActor
    func loadHandlesError() async {
        let routeRepo = MockRouteRepository()
        routeRepo.shouldThrow = true
        let (vm, _, _) = makeViewModel(routeRepo: routeRepo)

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Search Filter

    @Test("Filtered routes returns all when search is empty")
    @MainActor
    func filteredRoutesNoFilter() {
        let (vm, _, _) = makeViewModel()
        vm.routes = [makeRoute(name: "UTMB"), makeRoute(name: "CCC")]
        vm.searchText = ""

        #expect(vm.filteredRoutes.count == 2)
    }

    @Test("Filtered routes matches by name")
    @MainActor
    func filteredRoutesMatchesName() {
        let (vm, _, _) = makeViewModel()
        vm.routes = [makeRoute(name: "UTMB"), makeRoute(name: "CCC")]
        vm.searchText = "utmb"
        vm.debouncedSearchText = "utmb"

        #expect(vm.filteredRoutes.count == 1)
        #expect(vm.filteredRoutes.first?.name == "UTMB")
    }

    @Test("Filtered routes returns empty for no match")
    @MainActor
    func filteredRoutesNoMatch() {
        let (vm, _, _) = makeViewModel()
        vm.routes = [makeRoute(name: "UTMB")]
        vm.searchText = "xyz"
        vm.debouncedSearchText = "xyz"

        #expect(vm.filteredRoutes.isEmpty)
    }

    // MARK: - Delete

    @Test("Delete removes route from repository")
    @MainActor
    func deleteRoute() async {
        let routeRepo = MockRouteRepository()
        let route = makeRoute()
        routeRepo.routes = [route]
        let (vm, _, _) = makeViewModel(routeRepo: routeRepo)
        vm.routes = [route]

        await vm.deleteRoute(id: route.id)

        #expect(routeRepo.deletedId == route.id)
        #expect(vm.routes.isEmpty)
    }

    @Test("Delete handles error")
    @MainActor
    func deleteHandlesError() async {
        let routeRepo = MockRouteRepository()
        let route = makeRoute()
        routeRepo.routes = [route]
        routeRepo.shouldThrow = true
        let (vm, _, _) = makeViewModel(routeRepo: routeRepo)
        vm.routes = [route]

        await vm.deleteRoute(id: route.id)

        #expect(vm.error != nil)
    }
}
