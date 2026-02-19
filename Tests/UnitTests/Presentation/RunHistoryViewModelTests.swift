import Foundation
import Testing
@testable import UltraTrain

@Suite("RunHistory ViewModel Tests")
@MainActor
struct RunHistoryViewModelTests {

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600,
        averagePaceSecondsPerKm: Double = 360,
        notes: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            notes: notes,
            pausedDuration: 0
        )
    }

    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository()
    ) -> RunHistoryViewModel {
        RunHistoryViewModel(runRepository: runRepo)
    }

    // MARK: - Load

    @Test("Load fetches runs")
    func loadFetchesRuns() async {
        let repo = MockRunRepository()
        repo.runs = [makeRun(distanceKm: 10), makeRun(distanceKm: 15)]
        let vm = makeViewModel(runRepo: repo)
        await vm.load()
        #expect(vm.runs.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load empty repository returns empty list")
    func loadEmptyRepo() async {
        let vm = makeViewModel()
        await vm.load()
        #expect(vm.runs.isEmpty)
        #expect(vm.error == nil)
    }

    @Test("Load handles error")
    func loadHandlesError() async {
        let repo = MockRunRepository()
        repo.shouldThrow = true
        let vm = makeViewModel(runRepo: repo)
        await vm.load()
        #expect(vm.runs.isEmpty)
        #expect(vm.error != nil)
    }

    // MARK: - Delete

    @Test("Delete run removes from list")
    func deleteRun() async {
        let run = makeRun()
        let repo = MockRunRepository()
        repo.runs = [run]

        let vm = makeViewModel(runRepo: repo)
        vm.runs = [run]

        await vm.deleteRun(id: run.id)

        #expect(vm.runs.isEmpty)
        #expect(repo.deletedId == run.id)
        #expect(vm.error == nil)
    }

    @Test("Delete run handles error")
    func deleteRunError() async {
        let run = makeRun()
        let repo = MockRunRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(runRepo: repo)
        vm.runs = [run]

        await vm.deleteRun(id: run.id)

        #expect(vm.runs.count == 1)
        #expect(vm.error != nil)
    }

    // MARK: - Default Sort

    @Test("Default sort returns by date descending")
    func defaultSort() {
        let calendar = Calendar.current
        let old = makeRun(date: calendar.date(byAdding: .day, value: -7, to: .now)!)
        let recent = makeRun(date: calendar.date(byAdding: .day, value: -1, to: .now)!)

        let vm = makeViewModel()
        vm.runs = [old, recent]

        let filtered = vm.filteredRuns
        #expect(filtered[0].date > filtered[1].date)
    }

    // MARK: - Search

    @Test("Search filters by notes content")
    func searchFiltersByNotes() {
        let run1 = makeRun(notes: "Trail run in the mountains")
        let run2 = makeRun(notes: "Easy recovery jog")
        let run3 = makeRun(notes: nil)

        let vm = makeViewModel()
        vm.runs = [run1, run2, run3]
        vm.searchText = "mountain"

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == run1.id)
    }

    @Test("Search is case insensitive")
    func searchCaseInsensitive() {
        let run = makeRun(notes: "UTMB Training")
        let vm = makeViewModel()
        vm.runs = [run]
        vm.searchText = "utmb"

        #expect(vm.filteredRuns.count == 1)
    }

    @Test("Empty search returns all runs")
    func emptySearchReturnsAll() {
        let vm = makeViewModel()
        vm.runs = [makeRun(), makeRun(), makeRun()]
        vm.searchText = ""

        #expect(vm.filteredRuns.count == 3)
    }

    // MARK: - Time Period Filter

    @Test("This week filter shows only current week runs")
    func thisWeekFilter() {
        let calendar = Calendar.current
        let today = makeRun(date: .now)
        let lastMonth = makeRun(date: calendar.date(byAdding: .month, value: -1, to: .now)!)

        let vm = makeViewModel()
        vm.runs = [today, lastMonth]
        vm.selectedTimePeriod = .thisWeek

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == today.id)
    }

    @Test("This month filter shows only current month runs")
    func thisMonthFilter() {
        let calendar = Calendar.current
        let today = makeRun(date: .now)
        let lastYear = makeRun(date: calendar.date(byAdding: .year, value: -1, to: .now)!)

        let vm = makeViewModel()
        vm.runs = [today, lastYear]
        vm.selectedTimePeriod = .thisMonth

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == today.id)
    }

    @Test("This year filter shows only current year runs")
    func thisYearFilter() {
        let calendar = Calendar.current
        let today = makeRun(date: .now)
        let twoYearsAgo = makeRun(date: calendar.date(byAdding: .year, value: -2, to: .now)!)

        let vm = makeViewModel()
        vm.runs = [today, twoYearsAgo]
        vm.selectedTimePeriod = .thisYear

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == today.id)
    }

    @Test("Custom date range filter")
    func customDateRangeFilter() {
        let calendar = Calendar.current
        let jan15 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        let mar15 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 15))!

        let run1 = makeRun(date: jan15)
        let run2 = makeRun(date: feb15)
        let run3 = makeRun(date: mar15)

        let vm = makeViewModel()
        vm.runs = [run1, run2, run3]
        vm.selectedTimePeriod = .custom
        vm.customStartDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        vm.customEndDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == run2.id)
    }

    @Test("All time period returns all runs")
    func allTimePeriodReturnsAll() {
        let vm = makeViewModel()
        vm.runs = [makeRun(), makeRun(), makeRun()]
        vm.selectedTimePeriod = .all

        #expect(vm.filteredRuns.count == 3)
    }

    // MARK: - Sort Options

    @Test("Sort by distance longest first")
    func sortByDistanceLongest() {
        let short = makeRun(distanceKm: 5)
        let long = makeRun(distanceKm: 42)
        let medium = makeRun(distanceKm: 21)

        let vm = makeViewModel()
        vm.runs = [short, long, medium]
        vm.sortOption = .distanceLongest

        let filtered = vm.filteredRuns
        #expect(filtered[0].distanceKm == 42)
        #expect(filtered[1].distanceKm == 21)
        #expect(filtered[2].distanceKm == 5)
    }

    @Test("Sort by pace fastest first")
    func sortByPaceFastest() {
        let slow = makeRun(averagePaceSecondsPerKm: 420)
        let fast = makeRun(averagePaceSecondsPerKm: 300)

        let vm = makeViewModel()
        vm.runs = [slow, fast]
        vm.sortOption = .paceFastest

        #expect(vm.filteredRuns.first?.averagePaceSecondsPerKm == 300)
    }

    // MARK: - Summary Stats

    @Test("Filtered totals sum correctly")
    func filteredTotals() {
        let vm = makeViewModel()
        vm.runs = [
            makeRun(distanceKm: 10, elevationGainM: 500),
            makeRun(distanceKm: 15, elevationGainM: 300),
            makeRun(distanceKm: 20, elevationGainM: 200)
        ]
        #expect(vm.filteredTotalDistanceKm == 45)
        #expect(vm.filteredTotalElevationM == 1000)
        #expect(vm.filteredRunCount == 3)
    }

    // MARK: - Combined

    @Test("Search and filter combine correctly")
    func searchAndFilterCombine() {
        let calendar = Calendar.current
        let recentTrail = makeRun(date: .now, notes: "Trail run")
        let oldTrail = makeRun(
            date: calendar.date(byAdding: .year, value: -2, to: .now)!,
            notes: "Trail run"
        )
        let recentRoad = makeRun(date: .now, notes: "Road run")

        let vm = makeViewModel()
        vm.runs = [recentTrail, oldTrail, recentRoad]
        vm.searchText = "trail"
        vm.selectedTimePeriod = .thisYear

        #expect(vm.filteredRuns.count == 1)
        #expect(vm.filteredRuns.first?.id == recentTrail.id)
    }
}
