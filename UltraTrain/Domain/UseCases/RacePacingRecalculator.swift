import Foundation

enum RacePacingRecalculator {

    struct Input: Sendable {
        let segmentPacings: [TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing]
        let checkpointSplits: [CheckpointSplit]
        let crossedCheckpointIndex: Int
        let actualTimeAtCrossing: TimeInterval
        let predictedTimeAtCrossing: TimeInterval
        let targetFinishTime: TimeInterval
    }

    struct Result: Equatable, Sendable {
        let updatedPacings: [TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing]
        let recalculatedFinishTime: TimeInterval
    }

    static func recalculate(_ input: Input) -> Result {
        let crossedIndex = input.crossedCheckpointIndex
        guard crossedIndex < input.segmentPacings.count - 1 else {
            return Result(
                updatedPacings: input.segmentPacings,
                recalculatedFinishTime: input.targetFinishTime
            )
        }

        let remainingTime = input.targetFinishTime - input.actualTimeAtCrossing

        guard remainingTime > 0 else {
            return Result(
                updatedPacings: input.segmentPacings,
                recalculatedFinishTime: input.actualTimeAtCrossing
            )
        }

        let originalRemainingTime = input.targetFinishTime - input.predictedTimeAtCrossing
        guard originalRemainingTime > 0 else {
            return Result(
                updatedPacings: input.segmentPacings,
                recalculatedFinishTime: input.targetFinishTime
            )
        }

        let scaleFactor = remainingTime / originalRemainingTime
        var updatedPacings = input.segmentPacings
        var totalRecalculatedTime = input.actualTimeAtCrossing

        for i in (crossedIndex + 1)..<updatedPacings.count {
            let original = updatedPacings[i]
            var newTargetPace = original.targetPaceSecondsPerKm * scaleFactor

            newTargetPace = max(newTargetPace, original.aggressivePaceSecondsPerKm)
            newTargetPace = min(newTargetPace, original.conservativePaceSecondsPerKm)

            let segmentDistance = segmentDistanceKm(
                index: i,
                checkpointSplits: input.checkpointSplits
            )
            totalRecalculatedTime += newTargetPace * segmentDistance
            totalRecalculatedTime += original.aidStationDwellTime

            updatedPacings[i] = TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing(
                id: original.id,
                checkpointId: original.checkpointId,
                targetPaceSecondsPerKm: newTargetPace,
                conservativePaceSecondsPerKm: original.conservativePaceSecondsPerKm,
                aggressivePaceSecondsPerKm: original.aggressivePaceSecondsPerKm,
                pacingZone: original.pacingZone,
                aidStationDwellTime: original.aidStationDwellTime,
                targetHeartRateRange: original.targetHeartRateRange
            )
        }

        return Result(
            updatedPacings: updatedPacings,
            recalculatedFinishTime: totalRecalculatedTime
        )
    }

    private static func segmentDistanceKm(
        index: Int,
        checkpointSplits: [CheckpointSplit]
    ) -> Double {
        guard index < checkpointSplits.count else { return 0 }
        return checkpointSplits[index].segmentDistanceKm
    }
}
