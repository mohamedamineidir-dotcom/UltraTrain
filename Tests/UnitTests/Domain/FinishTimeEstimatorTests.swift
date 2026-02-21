import Foundation
import Testing
@testable import UltraTrain

@Suite("Finish Time Estimator Tests")
struct FinishTimeEstimatorTests {

    private let estimator = FinishTimeEstimator()

    private let athlete = Athlete(
        id: UUID(),
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

    private func makeRace(
        distanceKm: Double = 50,
        elevationGainM: Double = 3000,
        terrain: TerrainDifficulty = .easy,
        checkpoints: [Checkpoint] = []
    ) -> Race {
        Race(
            id: UUID(),
            name: "Test Race",
            date: Date.now.adding(days: 60),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: .aRace,
            goalType: .finish,
            checkpoints: checkpoints,
            terrainDifficulty: terrain
        )
    }

    private func makeRun(
        distanceKm: Double = 15,
        elevationGainM: Double = 500,
        duration: TimeInterval = 5400,
        linkedRaceId: UUID? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athlete.id,
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: duration / distanceKm,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: linkedRaceId,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeFitness(form: Double) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: .now,
            fitness: 50,
            fatigue: 50 - form,
            form: form,
            weeklyVolumeKm: 40,
            weeklyElevationGainM: 800,
            weeklyDuration: 14400,
            acuteToChronicRatio: 1.0,
            monotony: 0
        )
    }

    // MARK: - Basic

    @Test("Empty runs throws insufficientData")
    func emptyRunsThrows() async {
        let race = makeRace()
        await #expect(throws: DomainError.self) {
            try await estimator.execute(
                athlete: athlete, race: race,
                recentRuns: [], currentFitness: nil
            )
        }
    }

    @Test("Single run produces valid estimate")
    func singleRunValid() async throws {
        let race = makeRace()
        let run = makeRun()
        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: [run], currentFitness: nil
        )
        #expect(estimate.expectedTime > 0)
        #expect(estimate.optimisticTime > 0)
        #expect(estimate.conservativeTime > 0)
        #expect(estimate.raceId == race.id)
        #expect(estimate.athleteId == athlete.id)
    }

    @Test("Optimistic <= expected <= conservative")
    func scenarioOrdering() async throws {
        let race = makeRace()
        let runs = (0..<5).map { i in
            makeRun(duration: 5000 + Double(i) * 400)
        }
        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.optimisticTime <= estimate.expectedTime)
        #expect(estimate.expectedTime <= estimate.conservativeTime)
    }

    // MARK: - Terrain

    @Test("Terrain difficulty increases time")
    func terrainIncreasesTime() async throws {
        let easyRace = makeRace(terrain: .easy)
        let technicalRace = makeRace(terrain: .technical)
        let runs = [makeRun()]

        let easyEstimate = try await estimator.execute(
            athlete: athlete, race: easyRace,
            recentRuns: runs, currentFitness: nil
        )
        let techEstimate = try await estimator.execute(
            athlete: athlete, race: technicalRace,
            recentRuns: runs, currentFitness: nil
        )
        #expect(techEstimate.expectedTime > easyEstimate.expectedTime)
    }

    // MARK: - Form

    @Test("Positive form reduces expected time")
    func positiveFormHelps() async throws {
        let race = makeRace()
        let runs = [makeRun()]
        let fresh = makeFitness(form: 20)

        let neutralEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let freshEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: fresh
        )
        #expect(freshEstimate.expectedTime < neutralEstimate.expectedTime)
    }

    @Test("Negative form increases expected time")
    func negativeFormHurts() async throws {
        let race = makeRace()
        let runs = [makeRun()]
        let fatigued = makeFitness(form: -20)

        let neutralEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let fatiguedEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: fatigued
        )
        #expect(fatiguedEstimate.expectedTime > neutralEstimate.expectedTime)
    }

    // MARK: - Checkpoints

    @Test("Checkpoint splits are cumulative and ordered")
    func checkpointSplitsOrdered() async throws {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 10, elevationM: 500, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 25, elevationM: 1200, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP3", distanceFromStartKm: 40, elevationM: 800, hasAidStation: false)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.checkpointSplits.count == 3)
        for i in 1..<estimate.checkpointSplits.count {
            #expect(estimate.checkpointSplits[i].expectedTime > estimate.checkpointSplits[i - 1].expectedTime)
        }
    }

    @Test("Checkpoint splits include segment distance")
    func checkpointSplitsSegmentDistance() async throws {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 10, elevationM: 500, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 25, elevationM: 1200, hasAidStation: false),
            Checkpoint(id: UUID(), name: "CP3", distanceFromStartKm: 40, elevationM: 800, hasAidStation: true)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.checkpointSplits[0].segmentDistanceKm == 10)
        #expect(estimate.checkpointSplits[1].segmentDistanceKm == 15)
        #expect(estimate.checkpointSplits[2].segmentDistanceKm == 15)
        #expect(estimate.checkpointSplits[0].distanceFromStartKm == 10)
        #expect(estimate.checkpointSplits[1].distanceFromStartKm == 25)
        #expect(estimate.checkpointSplits[2].distanceFromStartKm == 40)
    }

    @Test("Checkpoint splits include segment elevation gain")
    func checkpointSplitsElevationGain() async throws {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 10, elevationM: 500, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 25, elevationM: 1200, hasAidStation: false),
            Checkpoint(id: UUID(), name: "CP3", distanceFromStartKm: 40, elevationM: 800, hasAidStation: false)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.checkpointSplits[0].segmentElevationGainM == 500)
        #expect(estimate.checkpointSplits[1].segmentElevationGainM == 700)
        // CP3 drops from 1200 to 800 — no gain
        #expect(estimate.checkpointSplits[2].segmentElevationGainM == 0)
    }

    @Test("Checkpoint splits include aid station flag")
    func checkpointSplitsAidStation() async throws {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 10, elevationM: 500, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 25, elevationM: 1200, hasAidStation: false)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.checkpointSplits[0].hasAidStation == true)
        #expect(estimate.checkpointSplits[1].hasAidStation == false)
    }

    @Test("Segment distances sum to total checkpoint distance")
    func segmentDistancesSumCorrectly() async throws {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 12, elevationM: 600, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 28, elevationM: 1400, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP3", distanceFromStartKm: 45, elevationM: 2500, hasAidStation: false)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let totalSegmentDistance = estimate.checkpointSplits.reduce(0.0) { $0 + $1.segmentDistanceKm }
        let lastCheckpointDistance = checkpoints.last!.distanceFromStartKm
        #expect(abs(totalSegmentDistance - lastCheckpointDistance) < 0.001)
    }

    // MARK: - Confidence

    @Test("Confidence increases with more runs")
    func confidenceWithRuns() async throws {
        let race = makeRace()
        let fewRuns = [makeRun()]
        let manyRuns = (0..<12).map { _ in makeRun() }

        let fewEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: fewRuns, currentFitness: nil
        )
        let manyEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: manyRuns, currentFitness: nil
        )
        #expect(manyEstimate.confidencePercent > fewEstimate.confidencePercent)
    }

    @Test("Confidence capped at 95%")
    func confidenceCapped() async throws {
        let race = makeRace(distanceKm: 20)
        let runs = (0..<15).map { _ in
            makeRun(distanceKm: 25, elevationGainM: 600)
        }
        let fitness = makeFitness(form: 10)

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: fitness
        )
        #expect(estimate.confidencePercent <= 95)
    }

    // MARK: - Race Feedback

    @Test("Race-linked run produces higher confidence than training-only runs")
    func raceLinkedHigherConfidence() async throws {
        let race = makeRace()
        let raceId = UUID()
        let trainingRuns = [makeRun()]
        let raceRuns = [makeRun(linkedRaceId: raceId)]

        let trainingEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: trainingRuns, currentFitness: nil
        )
        let raceEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: raceRuns, currentFitness: nil
        )
        #expect(raceEstimate.confidencePercent > trainingEstimate.confidencePercent)
    }

    @Test("Race-linked runs weight more heavily in prediction")
    func raceRunsWeightedHeavier() async throws {
        let race = makeRace()
        let raceId = UUID()
        let fastRaceRun = makeRun(duration: 4000, linkedRaceId: raceId)
        let slowRun = makeRun(duration: 7000)

        let mixedRuns = [fastRaceRun, slowRun]
        let mixedEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: mixedRuns, currentFitness: nil
        )

        let fastTrainingRun = makeRun(duration: 4000)
        let unweightedRuns = [fastTrainingRun, slowRun]
        let unweightedEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: unweightedRuns, currentFitness: nil
        )
        #expect(mixedEstimate.expectedTime < unweightedEstimate.expectedTime)
    }

    @Test("raceResultsUsed counts correctly")
    func raceResultsUsedCount() async throws {
        let race = makeRace()
        let raceId1 = UUID()
        let raceId2 = UUID()
        let runs = [
            makeRun(linkedRaceId: raceId1),
            makeRun(linkedRaceId: raceId2),
            makeRun()
        ]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.raceResultsUsed == 2)
    }

    @Test("No race-linked runs sets raceResultsUsed to zero")
    func noRaceResultsUsed() async throws {
        let race = makeRace()
        let runs = [makeRun(), makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.raceResultsUsed == 0)
    }

    @Test("Single race run with no training runs produces valid estimate")
    func singleRaceRunOnly() async throws {
        let race = makeRace()
        let raceId = UUID()
        let runs = [makeRun(linkedRaceId: raceId)]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.expectedTime > 0)
        #expect(estimate.raceResultsUsed == 1)
        #expect(estimate.confidencePercent > 40)
    }

    // MARK: - Distance Weighting

    @Test("Run closer to race distance has more influence")
    func distanceWeighting() async throws {
        let race = makeRace(distanceKm: 50, elevationGainM: 3000)
        let longRun = makeRun(distanceKm: 40, elevationGainM: 2000, duration: 18000)
        let shortRun = makeRun(distanceKm: 5, elevationGainM: 100, duration: 1500)

        let longOnlyEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: [longRun], currentFitness: nil
        )
        let mixedEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: [longRun, shortRun], currentFitness: nil
        )
        let diff = abs(longOnlyEstimate.expectedTime - mixedEstimate.expectedTime)
        let percentDiff = diff / longOnlyEstimate.expectedTime
        #expect(percentDiff < 0.15)
    }

    // MARK: - Continuous Form

    @Test("Small positive form gives slightly faster than neutral")
    func continuousFormSmallPositive() async throws {
        let race = makeRace()
        let runs = [makeRun()]
        let slightlyFresh = makeFitness(form: 5)

        let neutralEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let freshEstimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: slightlyFresh
        )
        #expect(freshEstimate.expectedTime < neutralEstimate.expectedTime)
    }

    // MARK: - Descent Penalty

    @Test("High descent ratio increases time")
    func descentPenaltyApplied() async throws {
        let flatRace = makeRace(distanceKm: 50, elevationGainM: 1000)
        let steepDescentRace = Race(
            id: UUID(),
            name: "Steep Race",
            date: Date.now.adding(days: 60),
            distanceKm: 50,
            elevationGainM: 1000,
            elevationLossM: 3000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .easy
        )
        let runs = [makeRun()]

        let flatEstimate = try await estimator.execute(
            athlete: athlete, race: flatRace,
            recentRuns: runs, currentFitness: nil
        )
        let steepEstimate = try await estimator.execute(
            athlete: athlete, race: steepDescentRace,
            recentRuns: runs, currentFitness: nil
        )
        #expect(steepEstimate.expectedTime > flatEstimate.expectedTime)
    }

    @Test("No descent penalty when ratio is low")
    func noDescentPenaltyLowRatio() async throws {
        let race = makeRace(distanceKm: 50, elevationGainM: 1000)
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(estimate.expectedTime > 0)
    }

    // MARK: - Ultra Fatigue

    @Test("Beginner on ultra is slower than advanced")
    func ultraFatigueBeginnerSlower() async throws {
        let race = makeRace(distanceKm: 120, elevationGainM: 6000)
        let runs = [makeRun()]

        let beginnerAthlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175, restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .beginner, weeklyVolumeKm: 50,
            longestRunKm: 30, preferredUnit: .metric
        )
        let advancedAthlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175, restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .advanced, weeklyVolumeKm: 50,
            longestRunKm: 30, preferredUnit: .metric
        )

        let beginnerEstimate = try await estimator.execute(
            athlete: beginnerAthlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let advancedEstimate = try await estimator.execute(
            athlete: advancedAthlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(beginnerEstimate.expectedTime > advancedEstimate.expectedTime)
    }

    @Test("Ultra fatigue has no effect under 60km")
    func ultraFatigueNoEffectShortRace() async throws {
        let race = makeRace(distanceKm: 40, elevationGainM: 2000)
        let runs = [makeRun()]

        let beginnerAthlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175, restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .beginner, weeklyVolumeKm: 50,
            longestRunKm: 30, preferredUnit: .metric
        )
        let eliteAthlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175, restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .elite, weeklyVolumeKm: 50,
            longestRunKm: 30, preferredUnit: .metric
        )

        let beginnerEstimate = try await estimator.execute(
            athlete: beginnerAthlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let eliteEstimate = try await estimator.execute(
            athlete: eliteAthlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        #expect(beginnerEstimate.expectedTime == eliteEstimate.expectedTime)
    }

    // MARK: - Calibration

    @Test("No calibrations returns factor of 1.0")
    func noCalibrationDefaultFactor() async throws {
        let race = makeRace()
        let runs = [makeRun()]
        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: []
        )
        #expect(estimate.calibrationFactor == 1.0)
    }

    @Test("Calibration reduces time when runner was faster")
    func calibrationReducesTimeWhenFaster() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let calibration = RaceCalibration(
            raceId: UUID(),
            predictedTime: 28800,
            actualTime: 25920,  // 10% faster
            raceDistanceKm: 50,
            raceElevationGainM: 3000
        )

        let uncalibrated = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: []
        )
        let calibrated = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [calibration]
        )

        #expect(calibrated.expectedTime < uncalibrated.expectedTime)
        #expect(calibrated.calibrationFactor < 1.0)
    }

    @Test("Calibration increases time when runner was slower")
    func calibrationIncreasesTimeWhenSlower() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let calibration = RaceCalibration(
            raceId: UUID(),
            predictedTime: 28800,
            actualTime: 31680,  // 10% slower
            raceDistanceKm: 50,
            raceElevationGainM: 3000
        )

        let uncalibrated = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: []
        )
        let calibrated = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [calibration]
        )

        #expect(calibrated.expectedTime > uncalibrated.expectedTime)
        #expect(calibrated.calibrationFactor > 1.0)
    }

    @Test("Calibration weighted by race similarity")
    func calibrationWeightedBySimilarity() async throws {
        let race = makeRace(distanceKm: 50, elevationGainM: 3000)
        let runs = [makeRun()]

        // Similar race: 50km — should dominate
        let similar = RaceCalibration(
            raceId: UUID(),
            predictedTime: 28800,
            actualTime: 25920,  // 10% faster
            raceDistanceKm: 50,
            raceElevationGainM: 3000
        )
        // Dissimilar race: 10km — should have less weight
        let dissimilar = RaceCalibration(
            raceId: UUID(),
            predictedTime: 3600,
            actualTime: 3960,  // 10% slower
            raceDistanceKm: 10,
            raceElevationGainM: 200
        )

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [similar, dissimilar]
        )

        // Similar race says faster (factor < 1), dissimilar says slower (factor > 1)
        // Because the similar race has higher weight, the overall factor should be < 1
        #expect(estimate.calibrationFactor < 1.0)
    }

    @Test("calibrationFactor stored in returned FinishEstimate")
    func calibrationFactorStoredInEstimate() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let calibration = RaceCalibration(
            raceId: UUID(),
            predictedTime: 28800,
            actualTime: 25920,
            raceDistanceKm: 50,
            raceElevationGainM: 3000
        )

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [calibration]
        )

        let expectedFactor = 25920.0 / 28800.0  // 0.9
        #expect(abs(estimate.calibrationFactor - expectedFactor) < 0.01)
    }

    // MARK: - Ultra Fatigue (cont.)

    // MARK: - Weather Impact

    @Test("Weather multiplier increases all scenario times")
    func weatherMultiplierIncreasesTime() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let weatherImpact = WeatherImpactCalculator.WeatherImpact(
            multiplier: 1.10, heatImpactPercent: 8.0, humidityCompoundPercent: 2.0,
            rainImpactPercent: 0, windImpactPercent: 0, coldImpactPercent: 0,
            summary: "Heat (+8.0%), Humidity (+2.0%)", severity: .moderate
        )

        let noWeather = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )
        let withWeather = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [],
            weatherImpact: weatherImpact
        )

        #expect(withWeather.expectedTime > noWeather.expectedTime)
        #expect(withWeather.optimisticTime > noWeather.optimisticTime)
        #expect(withWeather.conservativeTime > noWeather.conservativeTime)
    }

    @Test("Weather fields stored in returned FinishEstimate")
    func weatherFieldsStored() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let weatherImpact = WeatherImpactCalculator.WeatherImpact(
            multiplier: 1.05, heatImpactPercent: 4.0, humidityCompoundPercent: 1.0,
            rainImpactPercent: 0, windImpactPercent: 0, coldImpactPercent: 0,
            summary: "Heat (+4.0%), Humidity (+1.0%)", severity: .minor
        )

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil,
            pastRaceCalibrations: [],
            weatherImpact: weatherImpact
        )

        #expect(estimate.weatherMultiplier == 1.05)
        #expect(estimate.weatherImpactSummary == "Heat (+4.0%), Humidity (+1.0%)")
    }

    @Test("No weather impact returns nil weather fields")
    func noWeatherReturnsNilFields() async throws {
        let race = makeRace()
        let runs = [makeRun()]

        let estimate = try await estimator.execute(
            athlete: athlete, race: race,
            recentRuns: runs, currentFitness: nil
        )

        #expect(estimate.weatherMultiplier == nil)
        #expect(estimate.weatherImpactSummary == nil)
    }

    @Test("Elite has no ultra fatigue penalty even on long races")
    func eliteNoUltraPenalty() async throws {
        let shortRace = makeRace(distanceKm: 50, elevationGainM: 3000)
        let longRace = makeRace(distanceKm: 150, elevationGainM: 9000)
        let runs = [makeRun()]

        let eliteAthlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175, restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .elite, weeklyVolumeKm: 80,
            longestRunKm: 60, preferredUnit: .metric
        )

        let shortEstimate = try await estimator.execute(
            athlete: eliteAthlete, race: shortRace,
            recentRuns: runs, currentFitness: nil
        )
        let longEstimate = try await estimator.execute(
            athlete: eliteAthlete, race: longRace,
            recentRuns: runs, currentFitness: nil
        )
        let ratio = longEstimate.expectedTime / shortEstimate.expectedTime
        let effectiveRatio = longRace.effectiveDistanceKm / shortRace.effectiveDistanceKm
        let tolerance = 0.05
        #expect(abs(ratio - effectiveRatio) / effectiveRatio < tolerance)
    }
}
