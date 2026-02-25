import Foundation

extension TerrainAdaptivePacingCalculator {

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

    // MARK: - Heart Rate Range

    static func heartRateRange(
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

    // MARK: - Build Result

    static func buildResult(
        rawSegments: [(zone: RacePacingCalculator.PacingZone, rawPace: Double, distance: Double, split: CheckpointSplit)],
        scaleFactor: Double,
        input: AdaptiveInput,
        totalExpectedTime: TimeInterval,
        profile: TerrainPaceProfile
    ) -> AdaptivePacingResult {
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
}
