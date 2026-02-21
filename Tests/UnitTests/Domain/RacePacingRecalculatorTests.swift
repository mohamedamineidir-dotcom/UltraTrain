import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Pacing Recalculator Tests")
struct RacePacingRecalculatorTests {

    // MARK: - Helpers

    private func makeSegmentPacing(
        checkpointId: UUID = UUID(),
        targetPace: Double = 360,
        conservativePace: Double = 420,
        aggressivePace: Double = 300,
        zone: RacePacingCalculator.PacingZone = .moderate,
        dwellTime: TimeInterval = 0
    ) -> TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing {
        TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing(
            id: UUID(),
            checkpointId: checkpointId,
            targetPaceSecondsPerKm: targetPace,
            conservativePaceSecondsPerKm: conservativePace,
            aggressivePaceSecondsPerKm: aggressivePace,
            pacingZone: zone,
            aidStationDwellTime: dwellTime,
            targetHeartRateRange: nil
        )
    }

    private func makeSplit(
        checkpointId: UUID = UUID(),
        distanceKm: Double = 5,
        segmentDistanceKm: Double = 5,
        expectedTime: TimeInterval = 1800
    ) -> CheckpointSplit {
        CheckpointSplit(
            id: UUID(),
            checkpointId: checkpointId,
            checkpointName: "CP",
            distanceFromStartKm: distanceKm,
            segmentDistanceKm: segmentDistanceKm,
            segmentElevationGainM: 100,
            hasAidStation: false,
            optimisticTime: expectedTime * 0.9,
            expectedTime: expectedTime,
            conservativeTime: expectedTime * 1.1
        )
    }

    private func makeInput(
        segmentCount: Int = 3,
        crossedIndex: Int = 0,
        actualTime: TimeInterval = 1800,
        predictedTime: TimeInterval = 1800,
        targetFinish: TimeInterval = 5400
    ) -> RacePacingRecalculator.Input {
        let cpIds = (0..<segmentCount).map { _ in UUID() }
        let pacings = cpIds.map { id in
            makeSegmentPacing(checkpointId: id)
        }
        let splits = cpIds.enumerated().map { index, id in
            makeSplit(
                checkpointId: id,
                distanceKm: Double(index + 1) * 5,
                segmentDistanceKm: 5,
                expectedTime: Double(index + 1) * 1800
            )
        }
        return RacePacingRecalculator.Input(
            segmentPacings: pacings,
            checkpointSplits: splits,
            crossedCheckpointIndex: crossedIndex,
            actualTimeAtCrossing: actualTime,
            predictedTimeAtCrossing: predictedTime,
            targetFinishTime: targetFinish
        )
    }

    // MARK: - Tests

    @Test("No delta returns unchanged pacings")
    func noDeltaUnchanged() {
        let input = makeInput(
            actualTime: 1800,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].targetPaceSecondsPerKm == 360)
        #expect(result.updatedPacings[2].targetPaceSecondsPerKm == 360)
    }

    @Test("Ahead delta results in slower remaining paces")
    func aheadDelta() {
        let input = makeInput(
            actualTime: 1620,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].targetPaceSecondsPerKm > 360)
    }

    @Test("Behind delta results in faster remaining paces")
    func behindDelta() {
        let input = makeInput(
            actualTime: 1980,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].targetPaceSecondsPerKm < 360)
    }

    @Test("Pace clamped to aggressive limit")
    func clampToAggressive() {
        let input = makeInput(
            actualTime: 2400,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].targetPaceSecondsPerKm >= 300)
    }

    @Test("Pace clamped to conservative limit")
    func clampToConservative() {
        let input = makeInput(
            actualTime: 900,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].targetPaceSecondsPerKm <= 420)
    }

    @Test("Last segment returns unchanged")
    func lastSegmentUnchanged() {
        let input = makeInput(
            segmentCount: 3,
            crossedIndex: 2,
            actualTime: 5000,
            predictedTime: 5400,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings.count == 3)
    }

    @Test("Updated pacings preserve zone classification")
    func preservesZone() {
        let input = makeInput(actualTime: 1980, predictedTime: 1800, targetFinish: 5400)
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.updatedPacings[1].pacingZone == .moderate)
    }

    @Test("Recalculated finish time reflects adjustments")
    func finishTimeReflectsAdjustments() {
        let input = makeInput(
            actualTime: 1980,
            predictedTime: 1800,
            targetFinish: 5400
        )
        let result = RacePacingRecalculator.recalculate(input)
        #expect(result.recalculatedFinishTime > 0)
    }
}
