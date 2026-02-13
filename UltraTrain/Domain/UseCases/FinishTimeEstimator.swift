import Foundation

struct FinishTimeEstimator: EstimateFinishTimeUseCase, Sendable {

    // MARK: - Execute

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?
    ) async throws -> FinishEstimate {
        let paces = recentRuns.compactMap { pacePerEffectiveKm(for: $0) }
        guard !paces.isEmpty else {
            throw DomainError.insufficientData(reason: "At least one completed run is needed to estimate finish time")
        }

        let sortedPaces = paces.sorted()
        let pace25 = percentile(sortedPaces, p: 0.25)
        let medianPace = percentile(sortedPaces, p: 0.50)
        let pace75 = percentile(sortedPaces, p: 0.75)

        let terrain = terrainMultiplier(race.terrainDifficulty)
        let form = formMultiplier(currentFitness)
        let effectiveKm = race.effectiveDistanceKm

        let optimisticTime = effectiveKm * pace25 * terrain * 0.97
        let expectedTime = effectiveKm * medianPace * terrain * form
        let conservativeTime = effectiveKm * pace75 * terrain * 1.05

        let splits = calculateCheckpointSplits(
            race: race,
            optimistic: optimisticTime,
            expected: expectedTime,
            conservative: conservativeTime
        )

        let confidence = calculateConfidence(
            runs: recentRuns,
            fitness: currentFitness,
            race: race
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
            confidencePercent: confidence
        )
    }

    // MARK: - Pace

    private func pacePerEffectiveKm(for run: CompletedRun) -> Double? {
        let effectiveKm = run.distanceKm + (run.elevationGainM / 100.0)
        guard effectiveKm > 0, run.duration > 0 else { return nil }
        return run.duration / effectiveKm
    }

    private func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        if sorted.count == 1 { return sorted[0] }
        let index = p * Double(sorted.count - 1)
        let lower = Int(index)
        let upper = min(lower + 1, sorted.count - 1)
        let fraction = index - Double(lower)
        return sorted[lower] + fraction * (sorted[upper] - sorted[lower])
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
        if fitness.form > 10 { return 0.97 }
        if fitness.form < -10 { return 1.05 }
        return 1.0
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
        var segments: [(effort: Double, checkpoint: Checkpoint)] = []
        var previousDistanceKm = 0.0
        var previousElevationM = 0.0

        for checkpoint in sortedCheckpoints {
            let segmentDistance = checkpoint.distanceFromStartKm - previousDistanceKm
            let elevationChange = checkpoint.elevationM - previousElevationM
            let elevationGain = max(0, elevationChange)
            let effort = segmentDistance + (elevationGain / 100.0)
            segments.append((effort, checkpoint))
            previousDistanceKm = checkpoint.distanceFromStartKm
            previousElevationM = checkpoint.elevationM
        }

        let totalEffort = segments.reduce(0.0) { $0 + $1.effort }
        guard totalEffort > 0 else { return [] }

        var cumulativeEffort = 0.0
        return segments.map { segment in
            cumulativeEffort += segment.effort
            let fraction = cumulativeEffort / totalEffort
            return CheckpointSplit(
                id: UUID(),
                checkpointId: segment.checkpoint.id,
                checkpointName: segment.checkpoint.name,
                optimisticTime: optimistic * fraction,
                expectedTime: expected * fraction,
                conservativeTime: conservative * fraction
            )
        }
    }

    // MARK: - Confidence

    private func calculateConfidence(
        runs: [CompletedRun],
        fitness: FitnessSnapshot?,
        race: Race
    ) -> Double {
        var confidence = 40.0
        if runs.count > 5 { confidence += 10 }
        if runs.count > 10 { confidence += 10 }
        if fitness != nil { confidence += 10 }
        if runs.contains(where: { $0.distanceKm >= race.distanceKm * 0.5 }) { confidence += 15 }
        if runs.contains(where: { $0.elevationGainM >= 500 }) { confidence += 10 }
        return min(confidence, 95)
    }
}
