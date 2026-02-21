import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Pacing Calculator Tests")
struct RacePacingCalculatorTests {

    // MARK: - Helpers

    private func makeSplit(
        checkpointId: UUID = UUID(),
        name: String = "CP",
        distanceFromStart: Double = 10,
        segmentDistance: Double = 10,
        elevationGain: Double = 200,
        hasAidStation: Bool = false,
        optimistic: TimeInterval = 3000,
        expected: TimeInterval = 3600,
        conservative: TimeInterval = 4200
    ) -> CheckpointSplit {
        CheckpointSplit(
            id: UUID(),
            checkpointId: checkpointId,
            checkpointName: name,
            distanceFromStartKm: distanceFromStart,
            segmentDistanceKm: segmentDistance,
            segmentElevationGainM: elevationGain,
            hasAidStation: hasAidStation,
            optimisticTime: optimistic,
            expectedTime: expected,
            conservativeTime: conservative
        )
    }

    private func makeInput(
        splits: [CheckpointSplit],
        dwell: TimeInterval = 300,
        overrides: [UUID: TimeInterval] = [:]
    ) -> RacePacingCalculator.Input {
        RacePacingCalculator.Input(
            checkpointSplits: splits,
            defaultAidStationDwellSeconds: dwell,
            aidStationDwellOverrides: overrides
        )
    }

    // MARK: - Empty Input

    @Test("Empty splits returns zero result")
    func emptySplits() {
        let result = RacePacingCalculator.calculate(makeInput(splits: []))
        #expect(result.segmentPacings.isEmpty)
        #expect(result.totalDwellTime == 0)
        #expect(result.totalMovingTime == 0)
        #expect(result.totalTimeWithDwell == 0)
        #expect(result.averageTargetPaceSecondsPerKm == 0)
    }

    // MARK: - Pace Computation

    @Test("Computes target pace from expected time")
    func targetPace() {
        let split = makeSplit(segmentDistance: 10, expected: 3600)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].targetPaceSecondsPerKm == 360) // 3600 / 10
    }

    @Test("Computes aggressive pace from optimistic time")
    func aggressivePace() {
        let split = makeSplit(segmentDistance: 10, optimistic: 3000)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings[0].aggressivePaceSecondsPerKm == 300) // 3000 / 10
    }

    @Test("Computes conservative pace from conservative time")
    func conservativePace() {
        let split = makeSplit(segmentDistance: 10, conservative: 4200)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings[0].conservativePaceSecondsPerKm == 420) // 4200 / 10
    }

    @Test("Single segment computes correctly")
    func singleSegment() {
        let split = makeSplit(segmentDistance: 5, optimistic: 1500, expected: 1800, conservative: 2100)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.count == 1)
        #expect(result.segmentPacings[0].targetPaceSecondsPerKm == 360) // 1800 / 5
        #expect(result.segmentPacings[0].aggressivePaceSecondsPerKm == 300)
        #expect(result.segmentPacings[0].conservativePaceSecondsPerKm == 420)
    }

    @Test("Multi-segment uses cumulative time differences")
    func multiSegmentCumulative() {
        let cp1 = makeSplit(
            distanceFromStart: 10, segmentDistance: 10, elevationGain: 100,
            optimistic: 3000, expected: 3600, conservative: 4200
        )
        let cp2 = makeSplit(
            distanceFromStart: 20, segmentDistance: 10, elevationGain: 100,
            optimistic: 5800, expected: 7000, conservative: 8200
        )
        let result = RacePacingCalculator.calculate(makeInput(splits: [cp1, cp2]))
        #expect(result.segmentPacings.count == 2)
        // CP2: segment expected = 7000 - 3600 = 3400, pace = 3400 / 10 = 340
        #expect(result.segmentPacings[1].targetPaceSecondsPerKm == 340)
    }

    @Test("Zero-distance segment is skipped")
    func zeroDistanceSegment() {
        let split = makeSplit(segmentDistance: 0)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings.isEmpty)
    }

    // MARK: - Zone Classification

    @Test("Classifies steep segment as hard zone")
    func hardZone() {
        // 800m gain over 10km = 80 m/km > 60 threshold
        let split = makeSplit(segmentDistance: 10, elevationGain: 800)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings[0].pacingZone == .hard)
    }

    @Test("Classifies flat segment as easy zone")
    func easyZone() {
        // 100m gain over 10km = 10 m/km < 20 threshold
        let split = makeSplit(segmentDistance: 10, elevationGain: 100)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings[0].pacingZone == .easy)
    }

    @Test("Classifies moderate gradient as moderate zone")
    func moderateZone() {
        // 400m gain over 10km = 40 m/km (between 20 and 60)
        let split = makeSplit(segmentDistance: 10, elevationGain: 400)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split]))
        #expect(result.segmentPacings[0].pacingZone == .moderate)
    }

    // MARK: - Aid Station Dwell

    @Test("Aid station gets default dwell time")
    func aidStationDefaultDwell() {
        let split = makeSplit(hasAidStation: true)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split], dwell: 300))
        #expect(result.segmentPacings[0].aidStationDwellTime == 300)
    }

    @Test("Non-aid-station gets zero dwell time")
    func nonAidStationZeroDwell() {
        let split = makeSplit(hasAidStation: false)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split], dwell: 300))
        #expect(result.segmentPacings[0].aidStationDwellTime == 0)
    }

    @Test("Aid station dwell override takes precedence")
    func aidStationDwellOverride() {
        let cpId = UUID()
        let split = makeSplit(checkpointId: cpId, hasAidStation: true)
        let result = RacePacingCalculator.calculate(
            makeInput(splits: [split], dwell: 300, overrides: [cpId: 120])
        )
        #expect(result.segmentPacings[0].aidStationDwellTime == 120)
    }

    @Test("Total dwell time sums all aid station dwells")
    func totalDwellTimeSumsCorrectly() {
        let cp1 = makeSplit(
            distanceFromStart: 10, segmentDistance: 10, hasAidStation: true,
            optimistic: 3000, expected: 3600, conservative: 4200
        )
        let cp2 = makeSplit(
            distanceFromStart: 20, segmentDistance: 10, hasAidStation: true,
            optimistic: 6000, expected: 7200, conservative: 8400
        )
        let result = RacePacingCalculator.calculate(makeInput(splits: [cp1, cp2], dwell: 300))
        #expect(result.totalDwellTime == 600) // 300 + 300
    }

    // MARK: - Aggregates

    @Test("Average pace is distance-weighted")
    func averagePaceIsWeighted() {
        // CP1: 5km at 360 sec/km, CP2: 15km at 300 sec/km
        let cp1 = makeSplit(
            distanceFromStart: 5, segmentDistance: 5, elevationGain: 100,
            optimistic: 1500, expected: 1800, conservative: 2100
        )
        let cp2 = makeSplit(
            distanceFromStart: 20, segmentDistance: 15, elevationGain: 100,
            optimistic: 4500, expected: 6300, conservative: 8100
        )
        let result = RacePacingCalculator.calculate(makeInput(splits: [cp1, cp2]))
        // CP2 segment: 6300 - 1800 = 4500, pace = 4500 / 15 = 300
        // Weighted avg: (360*5 + 300*15) / 20 = (1800 + 4500) / 20 = 315
        #expect(result.averageTargetPaceSecondsPerKm == 315)
    }

    @Test("Total time with dwell equals moving time plus dwell")
    func totalTimeWithDwell() {
        let split = makeSplit(hasAidStation: true, expected: 3600)
        let result = RacePacingCalculator.calculate(makeInput(splits: [split], dwell: 300))
        #expect(result.totalMovingTime == 3600)
        #expect(result.totalTimeWithDwell == 3900) // 3600 + 300
    }

    // MARK: - PacingZone Enum

    @Test("PacingZone has four cases including descent")
    func testPacingZone_hasFourCases() {
        #expect(RacePacingCalculator.PacingZone.allCases.count == 4)
    }
}
