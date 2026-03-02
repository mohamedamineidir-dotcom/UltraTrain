import Foundation
import Testing
@testable import UltraTrain

@Suite("RunFrequencyHeatmapViewModel Tests")
struct RunFrequencyHeatmapViewModelTests {

    // MARK: - Helpers

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeTrackPoints(count: Int = 10) -> [TrackPoint] {
        let baseDate = Date.now.addingTimeInterval(-3600)
        var points: [TrackPoint] = []
        for index in 0..<count {
            let lat = 48.8566 + Double(index) * 0.0005
            let lon = 2.3522 + Double(index) * 0.0005
            let alt = 50.0 + Double(index) * 2.0
            let ts = baseDate.addingTimeInterval(Double(index) * 30)
            let hr = 140 + index
            points.append(TrackPoint(latitude: lat, longitude: lon, altitudeM: alt, timestamp: ts, heartRate: hr))
        }
        return points
    }

    private func makeRun(
        date: Date = .now,
        gpsTrack: [TrackPoint]? = nil
    ) -> CompletedRun {
        let track = gpsTrack ?? makeTrackPoints()
        return CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: date,
            distanceKm: 10.0,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: track,
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeSUT(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository()
    ) -> (RunFrequencyHeatmapViewModel, MockRunRepository, MockAthleteRepository) {
        let vm = RunFrequencyHeatmapViewModel(
            runRepository: runRepo,
            athleteRepository: athleteRepo
        )
        return (vm, runRepo, athleteRepo)
    }

    // MARK: - Tests

    @Test("Load returns early when no athlete exists")
    @MainActor
    func loadNoAthlete() async {
        let athleteRepo = MockAthleteRepository()
        let (vm, _, _) = makeSUT(athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.heatmapCells.isEmpty)
        #expect(vm.totalRunsIncluded == 0)
        #expect(vm.isLoading == false)
    }

    @Test("Load computes heatmap cells from runs with GPS data")
    @MainActor
    func loadComputesHeatmap() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [
            makeRun(date: Date.now),
            makeRun(date: Date.now.addingTimeInterval(-86400))
        ]
        let (vm, _, _) = makeSUT(runRepo: runRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(!vm.heatmapCells.isEmpty)
        #expect(vm.totalRunsIncluded == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load excludes runs without GPS tracks")
    @MainActor
    func loadExcludesEmptyTracks() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [
            makeRun(gpsTrack: []),
            makeRun(gpsTrack: makeTrackPoints(count: 10))
        ]
        let (vm, _, _) = makeSUT(runRepo: runRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.totalRunsIncluded == 1)
    }

    @Test("Load handles empty run list gracefully")
    @MainActor
    func loadEmptyRunList() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        let (vm, _, _) = makeSUT(runRepo: runRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.heatmapCells.isEmpty)
        #expect(vm.totalRunsIncluded == 0)
        #expect(vm.isLoading == false)
    }

    @Test("Load sets error when repository throws")
    @MainActor
    func loadSetsError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.shouldThrow = true
        let (vm, _, _) = makeSUT(runRepo: runRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load clears previous error on success")
    @MainActor
    func loadClearsPreviousError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        let (vm, _, _) = makeSUT(runRepo: runRepo, athleteRepo: athleteRepo)

        vm.error = "Previous error"

        await vm.load()

        #expect(vm.error == nil)
    }
}
