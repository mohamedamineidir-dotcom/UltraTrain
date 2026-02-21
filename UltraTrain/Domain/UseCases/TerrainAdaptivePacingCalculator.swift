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
            return AdaptivePacingResult(
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

        var pacings: [AdaptiveSegmentPacing] = []
        var totalDwell: TimeInterval = 0
        var weightedPaceSum: Double = 0
        var totalDistance: Double = 0

        let optimisticRatio = input.checkpointSplits.last.map {
            $0.optimisticTime / max($0.expectedTime, 1)
        } ?? 0.9
        let conservativeRatio = input.checkpointSplits.last.map {
            $0.conservativeTime / max($0.expectedTime, 1)
        } ?? 1.1

        for segment in rawSegments {
            let targetPace = segment.rawPace * scaleFactor
            let aggressivePace = targetPace * optimisticRatio
            let conservativePace = targetPace * conservativeRatio

            let dwell: TimeInterval
            if segment.split.hasAidStation {
                dwell = input.aidStationDwellOverrides[segment.split.checkpointId]
                    ?? input.defaultAidStationDwellSeconds
            } else {
                dwell = 0
            }

            let hrRange: ClosedRange<Int>?
            if input.pacingMode == .effort {
                hrRange = heartRateRange(for: segment.zone, athlete: input.athlete)
            } else {
                hrRange = nil
            }

            totalDwell += dwell
            weightedPaceSum += targetPace * segment.distance
            totalDistance += segment.distance

            pacings.append(AdaptiveSegmentPacing(
                id: UUID(),
                checkpointId: segment.split.checkpointId,
                targetPaceSecondsPerKm: targetPace,
                conservativePaceSecondsPerKm: conservativePace,
                aggressivePaceSecondsPerKm: aggressivePace,
                pacingZone: segment.zone,
                aidStationDwellTime: dwell,
                targetHeartRateRange: hrRange
            ))
        }

        let avgPace = totalDistance > 0 ? weightedPaceSum / totalDistance : 0

        return AdaptivePacingResult(
            segmentPacings: pacings,
            totalDwellTime: totalDwell,
            totalMovingTime: totalExpectedTime,
            totalTimeWithDwell: totalExpectedTime + totalDwell,
            averageTargetPaceSecondsPerKm: avgPace,
            terrainPaceProfile: profile
        )
    }

    // MARK: - Calibration

    static func calibrateFromHistory(
        runs: [CompletedRun],
        athlete: Athlete
    ) -> (climbRatio: Double, descentRatio: Double) {
        var uphillPaces: [Double] = []
        var flatPaces: [Double] = []
        var downhillPaces: [Double] = []

        for run in runs {
            for split in run.splits {
                guard split.duration > 0 else { continue }
                let pace = split.duration
                let change = split.elevationChangeM

                if change > 30 {
                    uphillPaces.append(pace)
                } else if change < -30 {
                    downhillPaces.append(pace)
                } else if abs(change) <= 10 {
                    flatPaces.append(pace)
                }
            }
        }

        guard flatPaces.count >= 3 else {
            return defaultRatios(experienceLevel: athlete.experienceLevel)
        }

        let avgFlat = flatPaces.reduce(0.0, +) / Double(flatPaces.count)
        guard avgFlat > 0 else {
            return defaultRatios(experienceLevel: athlete.experienceLevel)
        }

        let defaults = defaultRatios(experienceLevel: athlete.experienceLevel)

        let climbRatio: Double
        if uphillPaces.count >= 3 {
            let avgUphill = uphillPaces.reduce(0.0, +) / Double(uphillPaces.count)
            climbRatio = min(5.0, max(1.5, avgUphill / avgFlat))
        } else {
            climbRatio = defaults.climbRatio
        }

        let descentRatio: Double
        if downhillPaces.count >= 3 {
            let avgDownhill = downhillPaces.reduce(0.0, +) / Double(downhillPaces.count)
            descentRatio = min(0.95, max(0.5, avgDownhill / avgFlat))
        } else {
            descentRatio = defaults.descentRatio
        }

        return (climbRatio, descentRatio)
    }

    static func defaultRatios(
        experienceLevel: ExperienceLevel
    ) -> (climbRatio: Double, descentRatio: Double) {
        switch experienceLevel {
        case .beginner: (3.0, 0.85)
        case .intermediate: (2.5, 0.80)
        case .advanced: (2.2, 0.75)
        case .elite: (2.0, 0.70)
        }
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

    private static func heartRateRange(
        for zone: RacePacingCalculator.PacingZone,
        athlete: Athlete
    ) -> ClosedRange<Int> {
        let maxHR = athlete.maxHeartRate
        if let thresholds = athlete.customZoneThresholds, thresholds.count == 4 {
            switch zone {
            case .easy, .descent:
                return thresholds[0]...thresholds[1]
            case .moderate:
                return thresholds[1]...thresholds[2]
            case .hard:
                return thresholds[2]...thresholds[3]
            }
        }

        switch zone {
        case .easy, .descent:
            return Int(Double(maxHR) * 0.60)...Int(Double(maxHR) * 0.70)
        case .moderate:
            return Int(Double(maxHR) * 0.70)...Int(Double(maxHR) * 0.80)
        case .hard:
            return Int(Double(maxHR) * 0.75)...Int(Double(maxHR) * 0.85)
        }
    }

    private static func emptyResult() -> AdaptivePacingResult {
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
