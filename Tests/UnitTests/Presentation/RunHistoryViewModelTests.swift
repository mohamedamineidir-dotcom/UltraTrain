import Foundation
import Testing
@testable import UltraTrain

@Suite("RunHistory ViewModel Tests")
struct RunHistoryViewModelTests {

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            notes: nil
        )
    }

    @MainActor
    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository()
    ) -> RunHistoryViewModel {
        RunHistoryViewModel(runRepository: runRepo)
    }

    // MARK: - Load

    @Test("Load fetches runs")
    @MainActor
    func loadFetchesRuns() async {
        let run1 = makeRun(distanceKm: 10)
        let run2 = makeRun(distanceKm: 15)
        let repo = MockRunRepository()
        repo.runs = [run1, run2]

        let vm = makeViewModel(runRepo: repo)
        await vm.load()

        #expect(vm.runs.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load empty repository returns empty list")
    @MainActor
    func loadEmptyRepo() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.runs.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles error")
    @MainActor
    func loadHandlesError() async {
        let repo = MockRunRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(runRepo: repo)
        await vm.load()

        #expect(vm.runs.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Delete

    @Test("Delete run removes from list")
    @MainActor
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
    @MainActor
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

    // MARK: - Computed

    @Test("Sorted runs returns by date descending")
    @MainActor
    func sortedRuns() {
        let calendar = Calendar.current
        let old = makeRun(date: calendar.date(byAdding: .day, value: -7, to: .now)!)
        let recent = makeRun(date: calendar.date(byAdding: .day, value: -1, to: .now)!)

        let vm = makeViewModel()
        vm.runs = [old, recent]

        let sorted = vm.sortedRuns
        #expect(sorted[0].date > sorted[1].date)
    }
}
