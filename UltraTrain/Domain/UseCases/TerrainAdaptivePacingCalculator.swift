import Foundation

enum TerrainAdaptivePacingCalculator {

    // MARK: - Types

    enum PacingMode: String, CaseIterable, Sendable {
        case pace
        case effort
    }

    struct TerrainPaceProfile: Equatable, Sendable {
        let flatPaceSecondsPerKm: Double
        let moderateClimbPaceSecondsPerKm: Double
        let steepClimbPaceSecondsPerKm: Double
        let descentPaceSecondsPerKm: Double
    }

    struct AdaptiveSegmentPacing: Identifiable, Equatable, Sendable {
        let id: UUID
        let checkpointId: UUID
        let targetPaceSecondsPerKm: Double
        let conservativePaceSecondsPerKm: Double
        let aggressivePaceSecondsPerKm: Double
        let pacingZone: RacePacingCalculator.PacingZone
        let aidStationDwellTime: TimeInterval
        let targetHeartRateRange: ClosedRange<Int>?
    }

    struct AdaptiveInput: Sendable {
        let checkpointSplits: [CheckpointSplit]
        let defaultAidStationDwellSeconds: TimeInterval
        let aidStationDwellOverrides: [UUID: TimeInterval]
        let pacingMode: PacingMode
        let athlete: Athlete
        let recentRuns: [CompletedRun]
    }

    struct AdaptivePacingResult: Equatable, Sendable {
        let segmentPacings: [AdaptiveSegmentPacing]
        let totalDwellTime: TimeInterval
        let totalMovingTime: TimeInterval
        let totalTimeWithDwell: TimeInterval
        let averageTargetPaceSecondsPerKm: Double
        let terrainPaceProfile: TerrainPaceProfile
    }

    // MARK: - Calculate

    static func calculate(_ input: AdaptiveInput) -> AdaptivePacingResult {
        guard !input.checkpointSplits.isEmpty else {
            return emptyResult()
        }

        let totalExpectedTime = input.checkpointSplits.last?.expectedTime ?? 0
        let totalEffectiveKm = input.checkpointSplits.reduce(0.0) {
            $0 + $1.segmentDistanceKm + ($1.segmentElevationGainM / 100.0)
        }

        guard totalEffectiveKm > 0, totalExpectedTime > 0 else {
            return emptyResult()
        }

        let baseFlatPace = totalExpectedTime / totalEffectiveKm
        let (climbRatio, descentRatio) = calibrateFromHistory(
            runs: input.recentRuns,
            athlete: input.athlete
        )

        let moderateClimbRatio = 1.0 + (climbRatio - 1.0) * 0.5
        let profile = TerrainPaceProfile(
            flatPaceSecondsPerKm: baseFlatPace,
            moderateClimbPaceSecondsPerKm: baseFlatPace * moderateClimbRatio,
            steepClimbPaceSecondsPerKm: baseFlatPace * climbRatio,
            descentPaceSecondsPerKm: baseFlatPace * descentRatio
        )

        var rawSegments: [(zone: RacePacingCalculator.PacingZone, rawPace: Double, distance: Double, split: CheckpointSplit)] = []

        for split in input.checkpointSplits {
            let distance = split.segmentDistanceKm
            guard distance > 0 else { continue }

            let zone = classifyZone(
                elevationGainM: split.segmentElevationGainM,
                elevationLossM: split.segmentElevationLossM,
                distanceKm: distance
            )

            let rawPace: Double = switch zone {
            case .easy: profile.flatPaceSecondsPerKm
            case .moderate: profile.moderateClimbPaceSecondsPerKm
            case .hard: profile.steepClimbPaceSecondsPerKm
            case .descent: profile.descentPaceSecondsPerKm
            }

            rawSegments.append((zone, rawPace, distance, split))
        }

        let rawTotalTime = rawSegments.reduce(0.0) { $0 + $1.rawPace * $1.distance }
        let scaleFactor = rawTotalTime > 0 ? totalExpectedTime / rawTotalTime : 1.0

        return buildResult(
            rawSegments: rawSegments,
            scaleFactor: scaleFactor,
            input: input,
            totalExpectedTime: totalExpectedTime,
            profile: profile
        )
    }

    // MARK: - Private

    private static func classifyZone(
        elevationGainM: Double,
        elevationLossM: Double,
        distanceKm: Double
    ) -> RacePacingCalculator.PacingZone {
        guard distanceKm > 0 else { return .easy }

        let lossGradient = elevationLossM / distanceKm
        let gainGradient = elevationGainM / distanceKm

        if elevationLossM > elevationGainM &&
            lossGradient >= AppConfiguration.PacingStrategy.descentGradientThresholdMPerKm {
            return .descent
        }

        if gainGradient >= AppConfiguration.PacingStrategy.hardGradientThresholdMPerKm {
            return .hard
        }
        if gainGradient <= AppConfiguration.PacingStrategy.easyGradientThresholdMPerKm {
            return .easy
        }
        return .moderate
    }

    static func emptyResult() -> AdaptivePacingResult {
        AdaptivePacingResult(
            segmentPacings: [],
            totalDwellTime: 0,
            totalMovingTime: 0,
            totalTimeWithDwell: 0,
            averageTargetPaceSecondsPerKm: 0,
            terrainPaceProfile: TerrainPaceProfile(
                flatPaceSecondsPerKm: 0,
                moderateClimbPaceSecondsPerKm: 0,
                steepClimbPaceSecondsPerKm: 0,
                descentPaceSecondsPerKm: 0
            )
        )
    }
}
