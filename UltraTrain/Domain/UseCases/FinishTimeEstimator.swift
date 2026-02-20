import Foundation

struct FinishTimeEstimator: EstimateFinishTimeUseCase, Sendable {

    // MARK: - Execute

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?,
        pastRaceCalibrations: [RaceCalibration]
    ) async throws -> FinishEstimate {
        let raceLinkedRuns = recentRuns.filter { $0.linkedRaceId != nil }
        let raceResultsUsed = raceLinkedRuns.count
        let raceEffectiveKm = race.effectiveDistanceKm

        var weightedPaces: [(pace: Double, weight: Double)] = []
        for run in recentRuns {
            guard let pace = pacePerEffectiveKm(for: run) else { continue }
            let runEffectiveKm = run.distanceKm + (run.elevationGainM / 100.0)
            let distanceWeight = 1.0 / (1.0 + abs(runEffectiveKm - raceEffectiveKm) / max(raceEffectiveKm, 1))
            let raceBonus: Double = run.linkedRaceId != nil ? 3.0 : 1.0
            weightedPaces.append((pace, distanceWeight * raceBonus))
        }
        guard !weightedPaces.isEmpty else {
            throw DomainError.insufficientData(reason: "At least one completed run is needed to estimate finish time")
        }

        let pace25 = weightedPercentile(weightedPaces, p: 0.25)
        let medianPace = weightedPercentile(weightedPaces, p: 0.50)
        let pace75 = weightedPercentile(weightedPaces, p: 0.75)

        let terrain = terrainMultiplier(race.terrainDifficulty)
        let descent = descentPenalty(race)
        let form = formMultiplier(currentFitness)
        let ultra = ultraFatigueMultiplier(
            experienceLevel: athlete.experienceLevel,
            raceDistanceKm: race.distanceKm
        )
        let effectiveKm = raceEffectiveKm

        let calibration = computeCalibrationFactor(
            calibrations: pastRaceCalibrations,
            targetRace: race
        )

        let optimisticTime = effectiveKm * pace25 * terrain * descent * ultra * 0.97 * calibration
        let expectedTime = effectiveKm * medianPace * terrain * descent * form * ultra * calibration
        let conservativeTime = effectiveKm * pace75 * terrain * descent * ultra * 1.05 * calibration

        let splits = calculateCheckpointSplits(
            race: race,
            optimistic: optimisticTime,
            expected: expectedTime,
            conservative: conservativeTime
        )

        let confidence = calculateConfidence(
            runs: recentRuns,
            fitness: currentFitness,
            race: race,
            hasRaceResults: raceResultsUsed > 0
        )

        return FinishEstimate(
            id: UUID(),
            raceId: race.id,
            athleteId: athlete.id,
            calculatedAt: .now,
            optimisticTime: optimisticTime,
            expectedTime: expectedTime,
            conservativeTime: conservativeTime,
            checkpointSplits: splits,
            confidencePercent: confidence,
            raceResultsUsed: raceResultsUsed,
            calibrationFactor: calibration
        )
    }

    // MARK: - Pace

    private func pacePerEffectiveKm(for run: CompletedRun) -> Double? {
        let effectiveKm = run.distanceKm + (run.elevationGainM / 100.0)
        guard effectiveKm > 0, run.duration > 0 else { return nil }
        return run.duration / effectiveKm
    }

    private func weightedPercentile(
        _ weightedPaces: [(pace: Double, weight: Double)],
        p: Double
    ) -> Double {
        guard !weightedPaces.isEmpty else { return 0 }
        if weightedPaces.count == 1 { return weightedPaces[0].pace }
        let sorted = weightedPaces.sorted { $0.pace < $1.pace }
        let totalWeight = sorted.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return sorted[0].pace }

        var centers: [(pace: Double, position: Double)] = []
        var cumulative = 0.0
        for entry in sorted {
            let center = (cumulative + entry.weight / 2.0) / totalWeight
            centers.append((entry.pace, center))
            cumulative += entry.weight
        }

        if p <= centers.first!.position { return centers.first!.pace }
        if p >= centers.last!.position { return centers.last!.pace }

        for i in 1..<centers.count {
            if p <= centers[i].position {
                let prev = centers[i - 1]
                let curr = centers[i]
                let fraction = (p - prev.position) / (curr.position - prev.position)
                return prev.pace + fraction * (curr.pace - prev.pace)
            }
        }
        return centers.last!.pace
    }

    // MARK: - Adjustments

    private func terrainMultiplier(_ difficulty: TerrainDifficulty) -> Double {
        switch difficulty {
        case .easy: 1.0
        case .moderate: 1.05
        case .technical: 1.15
        case .extreme: 1.25
        }
    }

    private func formMultiplier(_ fitness: FitnessSnapshot?) -> Double {
        guard let fitness else { return 1.0 }
        return max(0.95, min(1.05, 1.0 - fitness.form * 0.003))
    }

    private func descentPenalty(_ race: Race) -> Double {
        let descentRatio = race.elevationLossM / max(race.distanceKm, 1)
        guard descentRatio > 30 else { return 1.0 }
        return min(1.10, 1.0 + (descentRatio - 30) * 0.002)
    }

    private func ultraFatigueMultiplier(
        experienceLevel: ExperienceLevel,
        raceDistanceKm: Double
    ) -> Double {
        guard raceDistanceKm > 60 else { return 1.0 }
        let distanceFactor = min(1.0, (raceDistanceKm - 60) / 90.0)
        let levelPenalty: Double = switch experienceLevel {
        case .beginner: 0.15
        case .intermediate: 0.08
        case .advanced: 0.03
        case .elite: 0.0
        }
        return 1.0 + distanceFactor * levelPenalty
    }

    // MARK: - Checkpoint Splits

    private func calculateCheckpointSplits(
        race: Race,
        optimistic: Double,
        expected: Double,
        conservative: Double
    ) -> [CheckpointSplit] {
        guard !race.checkpoints.isEmpty else { return [] }

        let sortedCheckpoints = race.checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        var segments: [(effort: Double, elevationGain: Double, checkpoint: Checkpoint)] = []
        var previousDistanceKm = 0.0
        var previousElevationM = 0.0

        for checkpoint in sortedCheckpoints {
            let segmentDistance = checkpoint.distanceFromStartKm - previousDistanceKm
            let elevationChange = checkpoint.elevationM - previousElevationM
            let elevationGain = max(0, elevationChange)
            let effort = segmentDistance + (elevationGain / 100.0)
            segments.append((effort, elevationGain, checkpoint))
            previousDistanceKm = checkpoint.distanceFromStartKm
            previousElevationM = checkpoint.elevationM
        }

        let totalEffort = segments.reduce(0.0) { $0 + $1.effort }
        guard totalEffort > 0 else { return [] }

        var cumulativeEffort = 0.0
        var prevDistKm = 0.0
        return segments.map { segment in
            cumulativeEffort += segment.effort
            let fraction = cumulativeEffort / totalEffort
            let segmentDistance = segment.checkpoint.distanceFromStartKm - prevDistKm
            prevDistKm = segment.checkpoint.distanceFromStartKm
            return CheckpointSplit(
                id: UUID(),
                checkpointId: segment.checkpoint.id,
                checkpointName: segment.checkpoint.name,
                distanceFromStartKm: segment.checkpoint.distanceFromStartKm,
                segmentDistanceKm: segmentDistance,
                segmentElevationGainM: segment.elevationGain,
                hasAidStation: segment.checkpoint.hasAidStation,
                optimisticTime: optimistic * fraction,
                expectedTime: expected * fraction,
                conservativeTime: conservative * fraction
            )
        }
    }

    // MARK: - Calibration

    private func computeCalibrationFactor(
        calibrations: [RaceCalibration],
        targetRace: Race
    ) -> Double {
        guard !calibrations.isEmpty else { return 1.0 }

        let targetEffectiveKm = targetRace.effectiveDistanceKm
        var totalWeight = 0.0
        var weightedSum = 0.0

        for cal in calibrations {
            guard cal.predictedTime > 0 else { continue }
            let ratio = cal.actualTime / cal.predictedTime
            let calEffectiveKm = cal.raceDistanceKm + (cal.raceElevationGainM / 100.0)
            let similarity = 1.0 / (1.0 + abs(calEffectiveKm - targetEffectiveKm) / max(targetEffectiveKm, 1))
            weightedSum += ratio * similarity
            totalWeight += similarity
        }

        guard totalWeight > 0 else { return 1.0 }
        return weightedSum / totalWeight
    }

    // MARK: - Confidence

    private func calculateConfidence(
        runs: [CompletedRun],
        fitness: FitnessSnapshot?,
        race: Race,
        hasRaceResults: Bool
    ) -> Double {
        var confidence = 40.0
        if runs.count > 5 { confidence += 10 }
        if runs.count > 10 { confidence += 10 }
        if fitness != nil { confidence += 10 }
        if runs.contains(where: { $0.distanceKm >= race.distanceKm * 0.5 }) { confidence += 15 }
        if runs.contains(where: { $0.elevationGainM >= 500 }) { confidence += 10 }
        if hasRaceResults { confidence += 15 }
        return min(confidence, 95)
    }
}
