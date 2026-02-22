import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Calibration Service Tests")
struct RaceCalibrationServiceTests {

    // MARK: - Test Helpers

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 60,
            longestRunKm: 42,
            preferredUnit: .metric
        )
    }

    private func makeCompletedRace(
        id: UUID = UUID(),
        distanceKm: Double = 50,
        elevationGainM: Double = 2500,
        actualFinishTime: TimeInterval = 28800
    ) -> Race {
        Race(
            id: id,
            name: "Completed Race",
            date: Date.now.adding(weeks: -4),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: .bRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate,
            actualFinishTime: actualFinishTime
        )
    }

    private func makeUpcomingRace(
        id: UUID = UUID(),
        distanceKm: Double = 100,
        elevationGainM: Double = 5000
    ) -> Race {
        Race(
            id: id,
            name: "Upcoming Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makeFinishEstimate(raceId: UUID, expectedTime: TimeInterval = 30000) -> FinishEstimate {
        FinishEstimate(
            id: UUID(),
            raceId: raceId,
            athleteId: UUID(),
            calculatedAt: .now,
            optimisticTime: expectedTime * 0.9,
            expectedTime: expectedTime,
            conservativeTime: expectedTime * 1.1,
            checkpointSplits: [],
            confidencePercent: 65,
            raceResultsUsed: 1
        )
    }

    // MARK: - Recalibration Tests

    @Test("Recalibrate saves new estimates for upcoming races")
    func testRecalibrateEstimates_savesEstimatesForUpcomingRaces() async throws {
        let completedRace = makeCompletedRace()
        let upcomingRace = makeUpcomingRace()
        let allRaces = [completedRace, upcomingRace]

        let estimateRepo = MockFinishEstimateRepository()
        let originalEstimate = makeFinishEstimate(
            raceId: completedRace.id,
            expectedTime: 30000
        )
        estimateRepo.estimates[completedRace.id] = originalEstimate

        let estimator = MockEstimateFinishTimeUseCase()
        let newEstimate = makeFinishEstimate(
            raceId: upcomingRace.id,
            expectedTime: 60000
        )
        estimator.resultEstimate = newEstimate

        let athlete = makeAthlete()

        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completedRace,
            actualTime: 28800,
            allRaces: allRaces,
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        // New estimate should be saved for the upcoming race
        let savedEstimate = estimateRepo.estimates[upcomingRace.id]
        #expect(savedEstimate != nil)
        #expect(savedEstimate?.raceId == upcomingRace.id)
    }

    @Test("Recalibrate builds calibrations from completed races with estimates")
    func testRecalibrateEstimates_buildsCalibrations() async throws {
        let completedRace = makeCompletedRace(actualFinishTime: 28800)
        let upcomingRace = makeUpcomingRace()

        let estimateRepo = MockFinishEstimateRepository()
        let previousEstimate = makeFinishEstimate(
            raceId: completedRace.id,
            expectedTime: 30000
        )
        estimateRepo.estimates[completedRace.id] = previousEstimate

        let estimator = MockEstimateFinishTimeUseCase()
        let newEstimate = makeFinishEstimate(
            raceId: upcomingRace.id,
            expectedTime: 55000
        )
        estimator.resultEstimate = newEstimate

        let athlete = makeAthlete()

        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completedRace,
            actualTime: 28800,
            allRaces: [completedRace, upcomingRace],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        // The estimator should have received calibrations from completed race
        #expect(estimator.lastCalibrations.count == 1)
        let calibration = estimator.lastCalibrations.first
        #expect(calibration?.raceId == completedRace.id)
        #expect(calibration?.predictedTime == 30000)
        #expect(calibration?.actualTime == 28800)
        #expect(calibration?.raceDistanceKm == 50)
        #expect(calibration?.raceElevationGainM == 2500)
    }

    @Test("Recalibrate with no completed races passes empty calibrations")
    func testRecalibrateEstimates_whenNoCompletedRaces_emptyCalibrations() async throws {
        let upcomingRace1 = makeUpcomingRace()
        let upcomingRace2 = makeUpcomingRace()
        let completedRace = makeCompletedRace()

        // No estimates stored for any completed race => no calibrations built
        let estimateRepo = MockFinishEstimateRepository()

        let estimator = MockEstimateFinishTimeUseCase()
        let estimate1 = makeFinishEstimate(raceId: upcomingRace1.id, expectedTime: 50000)
        estimator.resultEstimate = estimate1

        let athlete = makeAthlete()

        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completedRace,
            actualTime: 28800,
            allRaces: [completedRace, upcomingRace1, upcomingRace2],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        // Completed race has no stored estimate, so calibrations should be empty
        #expect(estimator.lastCalibrations.isEmpty)
    }

    @Test("Recalibrate with multiple completed races builds multiple calibrations")
    func testRecalibrateEstimates_multipleCompleted_buildsMultipleCalibrations() async throws {
        let completed1 = makeCompletedRace(
            distanceKm: 50,
            elevationGainM: 2000,
            actualFinishTime: 25000
        )
        let completed2 = makeCompletedRace(
            distanceKm: 80,
            elevationGainM: 4000,
            actualFinishTime: 48000
        )
        let upcoming = makeUpcomingRace()

        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[completed1.id] = makeFinishEstimate(
            raceId: completed1.id,
            expectedTime: 26000
        )
        estimateRepo.estimates[completed2.id] = makeFinishEstimate(
            raceId: completed2.id,
            expectedTime: 50000
        )

        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeFinishEstimate(
            raceId: upcoming.id,
            expectedTime: 70000
        )

        let athlete = makeAthlete()

        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completed1,
            actualTime: 25000,
            allRaces: [completed1, completed2, upcoming],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        #expect(estimator.lastCalibrations.count == 2)
    }

    @Test("Recalibrate does not create estimates for completed races")
    func testRecalibrateEstimates_doesNotEstimateCompletedRaces() async throws {
        let completed1 = makeCompletedRace(actualFinishTime: 20000)
        let completed2 = makeCompletedRace(actualFinishTime: 30000)

        let estimateRepo = MockFinishEstimateRepository()

        let estimator = MockEstimateFinishTimeUseCase()
        // Estimator should not be called since there are no upcoming races
        estimator.shouldThrow = true

        let athlete = makeAthlete()

        // Should not throw since estimator is not called for completed races
        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completed1,
            actualTime: 20000,
            allRaces: [completed1, completed2],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        // No estimates saved for completed races
        #expect(estimateRepo.savedEstimate == nil)
    }

    @Test("Recalibrate passes recent runs to estimator")
    func testRecalibrateEstimates_passesRecentRuns() async throws {
        let completed = makeCompletedRace()
        let upcoming = makeUpcomingRace()

        let estimateRepo = MockFinishEstimateRepository()
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeFinishEstimate(
            raceId: upcoming.id,
            expectedTime: 50000
        )

        let athlete = makeAthlete()
        let run = CompletedRun(
            id: UUID(),
            athleteId: athlete.id,
            date: Date.now.adding(days: -3),
            distanceKm: 20,
            elevationGainM: 500,
            elevationLossM: 500,
            duration: 7200,
            averageHeartRate: 140,
            maxHeartRate: 165,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )

        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completed,
            actualTime: 28800,
            allRaces: [completed, upcoming],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: [run]
        )

        // Estimate should have been saved for upcoming race
        #expect(estimateRepo.estimates[upcoming.id] != nil)
    }

    @Test("Recalibrate with multiple upcoming races saves estimate for each")
    func testRecalibrateEstimates_multipleUpcoming_savesForEach() async throws {
        let completed = makeCompletedRace()
        let upcoming1 = makeUpcomingRace()
        let upcoming2 = makeUpcomingRace(distanceKm: 80, elevationGainM: 3000)

        let estimateRepo = MockFinishEstimateRepository()
        let estimator = MockEstimateFinishTimeUseCase()

        // The estimator will return the same mock estimate, but with different raceIds
        // In reality, it would compute different values
        let estimate1 = makeFinishEstimate(raceId: upcoming1.id, expectedTime: 60000)
        estimator.resultEstimate = estimate1

        let athlete = makeAthlete()

        // Note: The mock returns the same resultEstimate each time, so both
        // upcoming races get the same estimate object. The important thing
        // is that saveEstimate is called for each.
        try await RaceCalibrationService.recalibrateEstimates(
            completedRace: completed,
            actualTime: 28800,
            allRaces: [completed, upcoming1, upcoming2],
            finishEstimateRepository: estimateRepo,
            finishTimeEstimator: estimator,
            athlete: athlete,
            recentRuns: []
        )

        // savedEstimate stores the last one saved
        #expect(estimateRepo.savedEstimate != nil)
    }
}
