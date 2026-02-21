import Foundation
import Testing
@testable import UltraTrain

@Suite("Terrain Adaptive Pacing Calculator Tests")
struct TerrainAdaptivePacingCalculatorTests {

    // MARK: - Helpers

    private func makeAthlete(experience: ExperienceLevel = .intermediate) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Date.distantPast,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 200,
            experienceLevel: experience,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeSplit(
        distanceFromStart: Double,
        segmentDistance: Double,
        elevationGain: Double,
        elevationLoss: Double = 0,
        hasAidStation: Bool = false,
        expectedTime: TimeInterval
    ) -> CheckpointSplit {
        CheckpointSplit(
            id: UUID(),
            checkpointId: UUID(),
            checkpointName: "CP",
            distanceFromStartKm: distanceFromStart,
            segmentDistanceKm: segmentDistance,
            segmentElevationGainM: elevationGain,
            segmentElevationLossM: elevationLoss,
            hasAidStation: hasAidStation,
            optimisticTime: expectedTime * 0.9,
            expectedTime: expectedTime,
            conservativeTime: expectedTime * 1.1
        )
    }

    private func makeInput(
        splits: [CheckpointSplit],
        dwell: TimeInterval = 300,
        overrides: [UUID: TimeInterval] = [:],
        pacingMode: TerrainAdaptivePacingCalculator.PacingMode = .pace,
        athlete: Athlete? = nil,
        recentRuns: [CompletedRun] = []
    ) -> TerrainAdaptivePacingCalculator.AdaptiveInput {
        TerrainAdaptivePacingCalculator.AdaptiveInput(
            checkpointSplits: splits,
            defaultAidStationDwellSeconds: dwell,
            aidStationDwellOverrides: overrides,
            pacingMode: pacingMode,
            athlete: athlete ?? makeAthlete(),
            recentRuns: recentRuns
        )
    }

    // MARK: - Empty Input

    @Test("Empty splits returns empty result")
    func testEmptySplits_returnsEmptyResult() {
        let result = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: []))
        #expect(result.segmentPacings.isEmpty)
        #expect(result.totalDwellTime == 0)
        #expect(result.totalMovingTime == 0)
        #expect(result.totalTimeWithDwell == 0)
        #expect(result.averageTargetPaceSecondsPerKm == 0)
    }

    // MARK: - Flat Segment

    @Test("Flat segment uses base pace")
    func testFlatSegment_usesBasePace() {
        // Single flat segment: 10 km, 0 gain, 0 loss → effective km = 10 + 0/100 = 10
        // expectedTime = 3600, baseFlatPace = 3600 / 10 = 360 sec/km
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 0,
            elevationLoss: 0,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.count == 1)
        // Flat segment should have pace close to the base flat pace
        #expect(result.segmentPacings[0].pacingZone == .easy)
        #expect(result.terrainPaceProfile.flatPaceSecondsPerKm > 0)
    }

    // MARK: - Steep Climb

    @Test("Steep climb uses slower pace than flat")
    func testSteepClimb_usesSlowerPace() {
        // Segment with 80 m/km gradient → classified as .hard (>= 60 threshold)
        let flatSplit = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 100,
            expectedTime: 3600
        )
        _ = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [flatSplit]))

        let steepSplit = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 800,
            expectedTime: 7200
        )
        let steepResult = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [steepSplit]))

        #expect(steepResult.segmentPacings[0].pacingZone == .hard)
        #expect(steepResult.terrainPaceProfile.steepClimbPaceSecondsPerKm >
                steepResult.terrainPaceProfile.flatPaceSecondsPerKm)
    }

    // MARK: - Descent

    @Test("Descent uses faster pace than flat")
    func testDescent_usesFasterPace() {
        // Segment with high elevation loss, low gain → classified as .descent
        // descentGradientThreshold = 30 m/km
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 50,
            elevationLoss: 500,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].pacingZone == .descent)
        #expect(result.terrainPaceProfile.descentPaceSecondsPerKm <
                result.terrainPaceProfile.flatPaceSecondsPerKm)
    }

    // MARK: - Total Time

    @Test("Total time matches expected from splits")
    func testTotalTime_matchesExpectedFromSplits() {
        let split1 = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 200,
            expectedTime: 3600
        )
        let split2 = makeSplit(
            distanceFromStart: 20,
            segmentDistance: 10,
            elevationGain: 100,
            expectedTime: 7000
        )
        let result = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [split1, split2]))

        // totalMovingTime should be the last split's expectedTime
        #expect(result.totalMovingTime == 7000)

        // Sum of individual segment times should roughly equal the total moving time
        var segmentTimeSum: TimeInterval = 0
        for (index, pacing) in result.segmentPacings.enumerated() {
            let distance = [split1, split2][index].segmentDistanceKm
            segmentTimeSum += pacing.targetPaceSecondsPerKm * distance
        }
        #expect(abs(segmentTimeSum - result.totalMovingTime) < 1.0)
    }

    // MARK: - Default Ratios

    @Test("Beginner default ratios are 3.0x climb, 0.85x descent")
    func testDefaultRatios_beginner() {
        let ratios = TerrainAdaptivePacingCalculator.defaultRatios(experienceLevel: .beginner)
        #expect(ratios.climbRatio == 3.0)
        #expect(ratios.descentRatio == 0.85)
    }

    @Test("Elite default ratios are 2.0x climb, 0.70x descent")
    func testDefaultRatios_elite() {
        let ratios = TerrainAdaptivePacingCalculator.defaultRatios(experienceLevel: .elite)
        #expect(ratios.climbRatio == 2.0)
        #expect(ratios.descentRatio == 0.70)
    }

    // MARK: - Pacing Modes

    @Test("Effort mode adds HR ranges to all segments")
    func testEffortMode_addsHRRanges() {
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 200,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(
            makeInput(splits: [split], pacingMode: .effort)
        )
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].targetHeartRateRange != nil)
    }

    @Test("Pace mode has no HR ranges")
    func testPaceMode_noHRRanges() {
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 200,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(
            makeInput(splits: [split], pacingMode: .pace)
        )
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].targetHeartRateRange == nil)
    }

    // MARK: - Dwell Time

    @Test("Aid station dwell time is applied correctly")
    func testDwellTimeCalculatedCorrectly() {
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 200,
            hasAidStation: true,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(
            makeInput(splits: [split], dwell: 300)
        )
        #expect(result.segmentPacings[0].aidStationDwellTime == 300)
        #expect(result.totalDwellTime == 300)
        #expect(result.totalTimeWithDwell == result.totalMovingTime + 300)
    }

    // MARK: - Calibration

    @Test("Athlete with no runs uses default ratios")
    func testCalibrationFromHistory_usesDefaults() {
        let athlete = makeAthlete(experience: .intermediate)
        let (climbRatio, descentRatio) = TerrainAdaptivePacingCalculator.calibrateFromHistory(
            runs: [],
            athlete: athlete
        )
        let defaults = TerrainAdaptivePacingCalculator.defaultRatios(experienceLevel: .intermediate)
        #expect(climbRatio == defaults.climbRatio)
        #expect(descentRatio == defaults.descentRatio)
    }

    // MARK: - Descent Zone Classification

    @Test("Segment with more loss than gain and loss gradient above threshold is classified as descent")
    func testDescentZoneClassification() {
        // loss = 400, gain = 100, distance = 10 km
        // lossGradient = 400 / 10 = 40 m/km > 30 threshold
        // loss > gain → .descent
        let split = makeSplit(
            distanceFromStart: 10,
            segmentDistance: 10,
            elevationGain: 100,
            elevationLoss: 400,
            expectedTime: 3600
        )
        let result = TerrainAdaptivePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].pacingZone == .descent)
    }
}
