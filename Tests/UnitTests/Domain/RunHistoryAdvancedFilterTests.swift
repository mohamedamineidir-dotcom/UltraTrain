import Foundation
import Testing
@testable import UltraTrain

@Suite("RunHistoryAdvancedFilter Tests")
struct RunHistoryAdvancedFilterTests {

    @Test("Default filter is not active")
    func defaultNotActive() {
        let filter = RunHistoryAdvancedFilter()
        #expect(filter.isActive == false)
        #expect(filter.activeFilterCount == 0)
    }

    @Test("Setting min distance makes filter active")
    func minDistanceActive() {
        var filter = RunHistoryAdvancedFilter()
        filter.minDistanceKm = 10
        #expect(filter.isActive == true)
        #expect(filter.activeFilterCount == 1)
    }

    @Test("Setting max elevation makes filter active")
    func maxElevationActive() {
        var filter = RunHistoryAdvancedFilter()
        filter.maxElevationM = 1000
        #expect(filter.isActive == true)
        #expect(filter.activeFilterCount == 1)
    }

    @Test("Multiple categories count correctly")
    func multipleCategories() {
        var filter = RunHistoryAdvancedFilter()
        filter.minDistanceKm = 5
        filter.maxDistanceKm = 50
        filter.sessionTypes = [.longRun]
        filter.gearIds = [UUID()]
        #expect(filter.activeFilterCount == 3)
    }

    @Test("All categories active counts to 5")
    func allCategoriesActive() {
        var filter = RunHistoryAdvancedFilter()
        filter.minDistanceKm = 5
        filter.minElevationM = 100
        filter.sessionTypes = [.tempo]
        filter.gearIds = [UUID()]
        filter.importSources = [.manual]
        #expect(filter.activeFilterCount == 5)
    }

    @Test("Distance min and max count as one category")
    func distanceRangeCountsAsOne() {
        var filter = RunHistoryAdvancedFilter()
        filter.minDistanceKm = 5
        filter.maxDistanceKm = 50
        #expect(filter.activeFilterCount == 1)
    }

    @Test("Clear all resets to default")
    func clearAllResets() {
        var filter = RunHistoryAdvancedFilter()
        filter.minDistanceKm = 10
        filter.maxElevationM = 500
        filter.sessionTypes = [.longRun, .tempo]
        filter.gearIds = [UUID()]
        filter.importSources = [.strava]

        filter.clearAll()

        #expect(filter.isActive == false)
        #expect(filter.activeFilterCount == 0)
        #expect(filter.minDistanceKm == nil)
        #expect(filter.maxElevationM == nil)
        #expect(filter.sessionTypes.isEmpty)
        #expect(filter.gearIds.isEmpty)
        #expect(filter.importSources.isEmpty)
    }

    @Test("Equatable works correctly")
    func equatable() {
        var a = RunHistoryAdvancedFilter()
        var b = RunHistoryAdvancedFilter()
        #expect(a == b)

        a.minDistanceKm = 10
        #expect(a != b)

        b.minDistanceKm = 10
        #expect(a == b)
    }
}
