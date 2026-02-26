import Foundation
import Testing
@testable import UltraTrain

@Suite("RunHistory ViewModel Advanced Filter Tests")
@MainActor
struct RunHistoryViewModelFilterTests {

    private let sessionId1 = UUID()
    private let sessionId2 = UUID()
    private let gearId1 = UUID()
    private let gearId2 = UUID()

    private func makeRun(
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        linkedSessionId: UUID? = nil,
        gearIds: [UUID] = [],
        isStravaImport: Bool = false,
        isHealthKitImport: Bool = false
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: linkedSessionId,
            notes: nil,
            pausedDuration: 0,
            gearIds: gearIds,
            isStravaImport: isStravaImport,
            isHealthKitImport: isHealthKitImport
        )
    }

    private func makeViewModel() -> RunHistoryViewModel {
        RunHistoryViewModel(runRepository: MockRunRepository())
    }

    // MARK: - Distance Filters

    @Test("Min distance filter excludes short runs")
    func minDistanceFilter() {
        let vm = makeViewModel()
        vm.runs = [makeRun(distanceKm: 5), makeRun(distanceKm: 15), makeRun(distanceKm: 25)]
        vm.advancedFilter.minDistanceKm = 10

        #expect(vm.filteredRuns.count == 2)
    }

    @Test("Max distance filter excludes long runs")
    func maxDistanceFilter() {
        let vm = makeViewModel()
        vm.runs = [makeRun(distanceKm: 5), makeRun(distanceKm: 15), makeRun(distanceKm: 25)]
        vm.advancedFilter.maxDistanceKm = 20

        #expect(vm.filteredRuns.count == 2)
    }

    @Test("Distance range filter includes boundary values")
    func distanceRangeBoundary() {
        let vm = makeViewModel()
        vm.runs = [makeRun(distanceKm: 10), makeRun(distanceKm: 20)]
        vm.advancedFilter.minDistanceKm = 10
        vm.advancedFilter.maxDistanceKm = 20

        #expect(vm.filteredRuns.count == 2)
    }

    @Test("Distance range filter excludes out-of-range runs")
    func distanceRangeExcludes() {
        let vm = makeViewModel()
        vm.runs = [makeRun(distanceKm: 5), makeRun(distanceKm: 15), makeRun(distanceKm: 30)]
        vm.advancedFilter.minDistanceKm = 10
        vm.advancedFilter.maxDistanceKm = 20

        #expect(vm.filteredRuns.count == 1)
    }

    // MARK: - Elevation Filters

    @Test("Min elevation filter excludes flat runs")
    func minElevationFilter() {
        let vm = makeViewModel()
        vm.runs = [makeRun(elevationGainM: 100), makeRun(elevationGainM: 500), makeRun(elevationGainM: 1000)]
        vm.advancedFilter.minElevationM = 300

        #expect(vm.filteredRuns.count == 2)
    }

    @Test("Max elevation filter excludes mountain runs")
    func maxElevationFilter() {
        let vm = makeViewModel()
        vm.runs = [makeRun(elevationGainM: 100), makeRun(elevationGainM: 500), makeRun(elevationGainM: 1000)]
        vm.advancedFilter.maxElevationM = 600

        #expect(vm.filteredRuns.count == 2)
    }

    // MARK: - Session Type Filters

    @Test("Session type filter matches linked sessions")
    func sessionTypeFilter() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(linkedSessionId: sessionId1),
            makeRun(linkedSessionId: sessionId2),
            makeRun()
        ]
        vm.sessionTypeLookup = [sessionId1: .longRun, sessionId2: .tempo]
        vm.advancedFilter.sessionTypes = [.longRun]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Session type filter excludes runs without linked session")
    func sessionTypeExcludesUnlinked() {
        let vm = makeViewModel()
        vm.runs = [makeRun(), makeRun(linkedSessionId: sessionId1)]
        vm.sessionTypeLookup = [sessionId1: .intervals]
        vm.advancedFilter.sessionTypes = [.intervals]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Multiple session types match any of them")
    func multipleSessionTypes() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(linkedSessionId: sessionId1),
            makeRun(linkedSessionId: sessionId2)
        ]
        vm.sessionTypeLookup = [sessionId1: .longRun, sessionId2: .tempo]
        vm.advancedFilter.sessionTypes = [.longRun, .tempo]

        #expect(vm.filteredRuns.count == 2)
    }

    // MARK: - Gear Filters

    @Test("Gear filter matches runs with specified gear")
    func gearFilter() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(gearIds: [gearId1]),
            makeRun(gearIds: [gearId2]),
            makeRun(gearIds: [])
        ]
        vm.advancedFilter.gearIds = [gearId1]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Gear filter matches run with multiple gear items")
    func gearFilterMultipleGear() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(gearIds: [gearId1, gearId2]),
            makeRun(gearIds: [])
        ]
        vm.advancedFilter.gearIds = [gearId1]

        #expect(vm.filteredRuns.count == 1)
    }

    // MARK: - Import Source Filters

    @Test("Manual import source filter")
    func manualImportFilter() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(),
            makeRun(isStravaImport: true),
            makeRun(isHealthKitImport: true)
        ]
        vm.advancedFilter.importSources = [.manual]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Strava import source filter")
    func stravaImportFilter() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(),
            makeRun(isStravaImport: true),
            makeRun(isHealthKitImport: true)
        ]
        vm.advancedFilter.importSources = [.strava]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("HealthKit import source filter")
    func healthKitImportFilter() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(),
            makeRun(isStravaImport: true),
            makeRun(isHealthKitImport: true)
        ]
        vm.advancedFilter.importSources = [.healthKit]

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Multiple import sources match any of them")
    func multipleImportSources() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(),
            makeRun(isStravaImport: true),
            makeRun(isHealthKitImport: true)
        ]
        vm.advancedFilter.importSources = [.manual, .strava]

        #expect(vm.filteredRuns.count == 2)
    }

    // MARK: - Combined Filters

    @Test("Advanced filter combines with text search")
    func advancedWithTextSearch() {
        let vm = makeViewModel()
        var run1 = makeRun(distanceKm: 20)
        run1.notes = "Trail run"
        var run2 = makeRun(distanceKm: 5)
        run2.notes = "Trail run"
        var run3 = makeRun(distanceKm: 20)
        run3.notes = "Road run"

        vm.runs = [run1, run2, run3]
        vm.searchText = "trail"
        vm.debouncedSearchText = "trail"
        vm.advancedFilter.minDistanceKm = 10

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == run1.id)
    }

    @Test("Advanced filter combines with distance and elevation")
    func distanceAndElevation() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(distanceKm: 20, elevationGainM: 800),
            makeRun(distanceKm: 20, elevationGainM: 100),
            makeRun(distanceKm: 5, elevationGainM: 800)
        ]
        vm.advancedFilter.minDistanceKm = 10
        vm.advancedFilter.minElevationM = 500

        #expect(vm.filteredRuns.count == 1)
    }

    // MARK: - Available Session Types

    @Test("Available session types reflects runs with linked sessions")
    func availableSessionTypes() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(linkedSessionId: sessionId1),
            makeRun(linkedSessionId: sessionId2),
            makeRun()
        ]
        vm.sessionTypeLookup = [sessionId1: .longRun, sessionId2: .tempo]

        let types = vm.availableSessionTypes
        #expect(types.count == 2)
        #expect(types.contains(.longRun))
        #expect(types.contains(.tempo))
    }

    // MARK: - Summary Stats with Filters

    @Test("Summary stats update with advanced filters")
    func summaryStatsWithFilters() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(distanceKm: 10, elevationGainM: 500),
            makeRun(distanceKm: 30, elevationGainM: 1500),
            makeRun(distanceKm: 5, elevationGainM: 100)
        ]
        vm.advancedFilter.minDistanceKm = 8

        #expect(vm.filteredRunCount == 2)
        #expect(vm.filteredTotalDistanceKm == 40)
        #expect(vm.filteredTotalElevationM == 2000)
    }

    // MARK: - Active Filter Count

    @Test("Active filter count from ViewModel")
    func activeFilterCountFromVM() {
        let vm = makeViewModel()
        #expect(vm.activeFilterCount == 0)

        vm.advancedFilter.minDistanceKm = 5
        vm.advancedFilter.gearIds = [gearId1]
        #expect(vm.activeFilterCount == 2)
    }

    // MARK: - No Advanced Filter

    @Test("No advanced filter returns all runs")
    func noAdvancedFilterReturnsAll() {
        let vm = makeViewModel()
        vm.runs = [makeRun(), makeRun(), makeRun()]

        #expect(vm.filteredRuns.count == 3)
    }
}
