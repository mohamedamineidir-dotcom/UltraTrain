import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Performance Comparison Tests")
struct RacePerformanceComparisonTests {

    private let startDate = Date(timeIntervalSince1970: 1_000_000)
    private let raceId = UUID()
    private let athleteId = UUID()
    private let cp1Id = UUID()
    private let cp2Id = UUID()

    private var race: Race {
        Race(
            id: raceId,
            name: "Test Ultra",
            date: startDate,
            distanceKm: 20,
            elevationGainM: 1000,
            elevationLossM: 1000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [
                Checkpoint(id: cp1Id, name: "CP1", distanceFromStartKm: 5, elevationM: 300, hasAidStation: true),
                Checkpoint(id: cp2Id, name: "CP2", distanceFromStartKm: 10, elevationM: 600, hasAidStation: false)
            ],
            terrainDifficulty: .moderate
        )
    }

    private var estimate: FinishEstimate {
        FinishEstimate(
            id: UUID(),
            raceId: raceId,
            athleteId: athleteId,
            calculatedAt: .now,
            optimisticTime: 5400,
            expectedTime: 7200, // 2h
            conservativeTime: 9000,
            checkpointSplits: [
                CheckpointSplit(
                    id: UUID(), checkpointId: cp1Id,
                    checkpointName: "CP1", distanceFromStartKm: 5,
                    segmentDistanceKm: 5, segmentElevationGainM: 300,
                    hasAidStation: true,
                    optimisticTime: 1500, expectedTime: 1800, conservativeTime: 2100
                ),
                CheckpointSplit(
                    id: UUID(), checkpointId: cp2Id,
                    checkpointName: "CP2", distanceFromStartKm: 10,
                    segmentDistanceKm: 5, segmentElevationGainM: 300,
                    hasAidStation: false,
                    optimisticTime: 3000, expectedTime: 3600, conservativeTime: 4200
                )
            ],
            confidencePercent: 60,
            raceResultsUsed: 0
        )
    }

    // ~1km apart along longitude, 10 min intervals
    private func makeTrack(pointCount: Int, intervalSeconds: TimeInterval = 600) -> [TrackPoint] {
        (0..<pointCount).map { i in
            TrackPoint(
                latitude: 0.0,
                longitude: Double(i) * 0.009,
                altitudeM: 100,
                timestamp: startDate.addingTimeInterval(Double(i) * intervalSeconds),
                heartRate: nil
            )
        }
    }

    private func makeRun(gpsTrack: [TrackPoint], duration: TimeInterval) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: startDate,
            distanceKm: 20,
            elevationGainM: 1000,
            elevationLossM: 1000,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: duration / 20,
            gpsTrack: gpsTrack,
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: raceId,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeDeps(
        run: CompletedRun
    ) -> (MockTrainingPlanRepository, MockAthleteRepository, MockRaceRepository, MockRunRepository, MockFinishEstimateRepository) {
        let planRepo = MockTrainingPlanRepository()
        let athleteRepo = MockAthleteRepository()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let runRepo = MockRunRepository()
        runRepo.runs = [run]
        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[raceId] = estimate
        return (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo)
    }

    @Test("Comparison built correctly from estimate and GPS timestamps")
    @MainActor
    func comparisonBuiltCorrectly() async {
        let track = makeTrack(pointCount: 25)
        let run = makeRun(gpsTrack: track, duration: 7000)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        #expect(vm.racePerformance != nil)
        #expect(vm.racePerformance?.checkpointComparisons.count == 2)
        #expect(vm.racePerformance?.checkpointComparisons[0].checkpointName == "CP1")
        #expect(vm.racePerformance?.checkpointComparisons[1].checkpointName == "CP2")
    }

    @Test("Delta negative when actual is faster than predicted")
    @MainActor
    func deltaNegativeWhenFaster() async {
        // Track with 5min intervals instead of 10min — runner is faster
        let track = makeTrack(pointCount: 25, intervalSeconds: 300)
        let run = makeRun(gpsTrack: track, duration: 6000)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        guard let performance = vm.racePerformance else {
            Issue.record("Expected racePerformance to be set")
            return
        }

        // With 5min intervals, CP1 at 5km ≈ 1500s actual vs 1800s predicted → delta < 0
        #expect(performance.checkpointComparisons[0].delta < 0)
    }

    @Test("Delta positive when actual is slower than predicted")
    @MainActor
    func deltaPositiveWhenSlower() async {
        // Track with 15min intervals — runner is slower
        let track = makeTrack(pointCount: 25, intervalSeconds: 900)
        let run = makeRun(gpsTrack: track, duration: 9000)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        guard let performance = vm.racePerformance else {
            Issue.record("Expected racePerformance to be set")
            return
        }

        // With 15min intervals, CP1 at 5km ≈ 4500s actual vs 1800s predicted → delta > 0
        #expect(performance.checkpointComparisons[0].delta > 0)
    }

    @Test("Finish delta matches run duration minus predicted")
    @MainActor
    func finishDeltaCorrect() async {
        let track = makeTrack(pointCount: 25)
        let duration: TimeInterval = 8000
        let run = makeRun(gpsTrack: track, duration: duration)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        guard let performance = vm.racePerformance else {
            Issue.record("Expected racePerformance to be set")
            return
        }

        let expectedDelta = duration - estimate.expectedTime
        #expect(abs(performance.finishDelta - expectedDelta) < 1)
    }

    @Test("No comparison when estimate has no checkpoint splits")
    @MainActor
    func noComparisonWithoutSplits() async {
        let track = makeTrack(pointCount: 25)
        let run = makeRun(gpsTrack: track, duration: 7200)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        // Replace with an estimate that has no splits
        estimateRepo.estimates[raceId] = FinishEstimate(
            id: UUID(), raceId: raceId, athleteId: athleteId,
            calculatedAt: .now, optimisticTime: 5400, expectedTime: 7200,
            conservativeTime: 9000, checkpointSplits: [],
            confidencePercent: 50, raceResultsUsed: 0
        )

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        #expect(vm.racePerformance == nil)
    }

    @Test("No comparison when run has no GPS track")
    @MainActor
    func noComparisonWithoutGPS() async {
        let run = makeRun(gpsTrack: [], duration: 7200)
        let (planRepo, athleteRepo, raceRepo, runRepo, estimateRepo) = makeDeps(run: run)

        let vm = RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo,
            exportService: MockExportService()
        )

        await vm.load()

        #expect(vm.racePerformance == nil)
    }
}
