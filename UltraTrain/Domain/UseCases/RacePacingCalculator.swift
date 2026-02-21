import Foundation

enum RacePacingCalculator {

    // MARK: - Types

    struct SegmentPacing: Identifiable, Equatable, Sendable {
        let id: UUID
        let checkpointId: UUID
        let targetPaceSecondsPerKm: Double
        let conservativePaceSecondsPerKm: Double
        let aggressivePaceSecondsPerKm: Double
        let pacingZone: PacingZone
        let aidStationDwellTime: TimeInterval
    }

    enum PacingZone: String, Sendable, Equatable, CaseIterable {
        case easy
        case moderate
        case hard
        case descent
    }

    struct Input: Sendable {
        let checkpointSplits: [CheckpointSplit]
        let defaultAidStationDwellSeconds: TimeInterval
        let aidStationDwellOverrides: [UUID: TimeInterval]
    }

    struct PacingResult: Equatable, Sendable {
        let segmentPacings: [SegmentPacing]
        let totalDwellTime: TimeInterval
        let totalMovingTime: TimeInterval
        let totalTimeWithDwell: TimeInterval
        let averageTargetPaceSecondsPerKm: Double
    }

    // MARK: - Calculate

    static func calculate(_ input: Input) -> PacingResult {
        guard !input.checkpointSplits.isEmpty else {
            return PacingResult(
                segmentPacings: [],
                totalDwellTime: 0,
                totalMovingTime: 0,
                totalTimeWithDwell: 0,
                averageTargetPaceSecondsPerKm: 0
            )
        }

        var pacings: [SegmentPacing] = []
        var totalDwell: TimeInterval = 0
        var weightedPaceSum: Double = 0
        var totalDistance: Double = 0
        var previousExpected: TimeInterval = 0
        var previousOptimistic: TimeInterval = 0
        var previousConservative: TimeInterval = 0

        for split in input.checkpointSplits {
            let segmentExpected = split.expectedTime - previousExpected
            let segmentOptimistic = split.optimisticTime - previousOptimistic
            let segmentConservative = split.conservativeTime - previousConservative

            let distance = split.segmentDistanceKm
            guard distance > 0 else {
                previousExpected = split.expectedTime
                previousOptimistic = split.optimisticTime
                previousConservative = split.conservativeTime
                continue
            }

            let targetPace = segmentExpected / distance
            let aggressivePace = segmentOptimistic / distance
            let conservativePace = segmentConservative / distance

            let zone = classifyZone(
                elevationGainM: split.segmentElevationGainM,
                distanceKm: distance
            )

            let dwell: TimeInterval
            if split.hasAidStation {
                dwell = input.aidStationDwellOverrides[split.checkpointId]
                    ?? input.defaultAidStationDwellSeconds
            } else {
                dwell = 0
            }

            totalDwell += dwell
            weightedPaceSum += targetPace * distance
            totalDistance += distance

            pacings.append(SegmentPacing(
                id: UUID(),
                checkpointId: split.checkpointId,
                targetPaceSecondsPerKm: targetPace,
                conservativePaceSecondsPerKm: conservativePace,
                aggressivePaceSecondsPerKm: aggressivePace,
                pacingZone: zone,
                aidStationDwellTime: dwell
            ))

            previousExpected = split.expectedTime
            previousOptimistic = split.optimisticTime
            previousConservative = split.conservativeTime
        }

        let movingTime = previousExpected
        let avgPace = totalDistance > 0 ? weightedPaceSum / totalDistance : 0

        return PacingResult(
            segmentPacings: pacings,
            totalDwellTime: totalDwell,
            totalMovingTime: movingTime,
            totalTimeWithDwell: movingTime + totalDwell,
            averageTargetPaceSecondsPerKm: avgPace
        )
    }

    // MARK: - Private

    private static func classifyZone(
        elevationGainM: Double,
        distanceKm: Double
    ) -> PacingZone {
        let gradientMPerKm = elevationGainM / distanceKm
        if gradientMPerKm >= AppConfiguration.PacingStrategy.hardGradientThresholdMPerKm {
            return .hard
        }
        if gradientMPerKm <= AppConfiguration.PacingStrategy.easyGradientThresholdMPerKm {
            return .easy
        }
        return .moderate
    }
}
