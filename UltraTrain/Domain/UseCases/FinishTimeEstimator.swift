import Foundation

struct FinishTimeEstimator: EstimateFinishTimeUseCase, Sendable {

    private let mlPredictionService: (any FinishTimePredictionServiceProtocol)?

    init(mlPredictionService: (any FinishTimePredictionServiceProtocol)? = nil) {
        self.mlPredictionService = mlPredictionService
    }

    /// Where the prediction's pace anchor came from. Drives range
    /// width: runs-based has within-run variance baked in (use pace25
    /// / pace75 percentiles), PB-based has no variance so we add an
    /// explicit aleatory + epistemic spread, fallback gets the widest
    /// spread (very low certainty).
    enum PredictionSource: Sendable {
        case runs           // ≥ 1 completed run with pace data
        case personalBests  // PBs converted via Riegel + Kilian
        case experienceFallback  // experience-level fallback only
    }

    // MARK: - Execute

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?,
        pastRaceCalibrations: [RaceCalibration],
        weatherImpact: WeatherImpactCalculator.WeatherImpact?
    ) async throws -> FinishEstimate {
        let raceLinkedRuns = recentRuns.filter { $0.linkedRaceId != nil }
        let raceResultsUsed = raceLinkedRuns.count
        let raceEffectiveKm = race.effectiveDistanceKm

        // Pace anchor: prefer recent runs; fall back to PBs (Riegel +
        // Kilian for trail); last resort is experience-level fallback.
        // Day-0 prediction is a first-class citizen: athletes get a
        // credible range from their PBs alone before logging any
        // training. The range widens as data quality decreases.
        var weightedPaces: [(pace: Double, weight: Double)] = []
        for run in recentRuns {
            guard let pace = pacePerEffectiveKm(for: run) else { continue }
            let runEffectiveKm = run.distanceKm + (run.elevationGainM / 100.0)
            let distanceWeight = 1.0 / (1.0 + abs(runEffectiveKm - raceEffectiveKm) / max(raceEffectiveKm, 1))
            let raceBonus: Double = run.linkedRaceId != nil ? 3.0 : 1.0
            weightedPaces.append((pace, distanceWeight * raceBonus))
        }

        let source: PredictionSource
        if !weightedPaces.isEmpty {
            source = .runs
        } else {
            let pbPaces = pbsAsWeightedPaces(athlete: athlete, race: race, raceEffectiveKm: raceEffectiveKm)
            if !pbPaces.isEmpty {
                weightedPaces = pbPaces
                source = .personalBests
            } else {
                let fallbackTime = race.estimatedDuration(experience: athlete.experienceLevel)
                let fallbackPace = fallbackTime / max(raceEffectiveKm, 1)
                weightedPaces = [(fallbackPace, 1.0)]
                source = .experienceFallback
            }
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

        let weather = weatherImpact?.multiplier ?? 1.0

        let algorithmicExpected = effectiveKm * medianPace * terrain * descent * form * ultra * calibration * weather

        // Source-dependent range. When we have runs, the percentile
        // spread (pace25 / pace75) already captures within-athlete
        // variance — combined with a small ±3-5% safety margin.
        // For PB / fallback predictions there's no run-level variance,
        // so we synthesise the spread from race-class aleatory
        // uncertainty (heat / GI / pacing variability) + epistemic
        // uncertainty (how well we know athlete's fitness from the
        // available signal). Asymmetric: things go wrong more often
        // than right, so the conservative side is wider.
        let optimisticTime: Double
        let conservativeTime: Double
        switch source {
        case .runs:
            optimisticTime = effectiveKm * pace25 * terrain * descent * ultra * 0.97 * calibration * weather
            conservativeTime = effectiveKm * pace75 * terrain * descent * ultra * 1.05 * calibration * weather
        case .personalBests, .experienceFallback:
            let aleatoryPct = aleatorySpread(race: race)
            let epistemicPct = epistemicSpread(source: source, athlete: athlete, race: race)
            let totalSpread = (aleatoryPct * aleatoryPct + epistemicPct * epistemicPct).squareRoot()
            optimisticTime = algorithmicExpected * (1.0 - totalSpread)
            conservativeTime = algorithmicExpected * (1.0 + totalSpread * 1.4)
        }

        let avgPace = weightedPaces.reduce(0.0) { $0 + $1.pace * $1.weight }
            / weightedPaces.reduce(0.0) { $0 + $1.weight }
        let terrainNumeric: Double = switch race.terrainDifficulty {
        case .easy: 1.0
        case .moderate: 1.05
        case .technical: 1.15
        case .extreme: 1.25
        }
        let mlBlend = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicExpected,
            mlPredictionService: mlPredictionService,
            effectiveDistanceKm: effectiveKm,
            experienceLevel: athlete.experienceLevel,
            recentAvgPaceSecondsPerKm: avgPace,
            ctl: currentFitness?.fitness ?? 0,
            tsb: currentFitness?.form ?? 0,
            terrainDifficulty: terrainNumeric,
            elevationPerKm: race.elevationGainM / max(race.distanceKm, 1),
            calibrationFactor: calibration,
            runCount: recentRuns.count
        )
        let expectedTime = mlBlend.blendWeight > 0 ? mlBlend.predictedTimeSeconds : algorithmicExpected

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
            calibrationFactor: calibration,
            weatherMultiplier: weatherImpact?.multiplier,
            weatherImpactSummary: weatherImpact?.summary
        )
    }

    // MARK: - PB-based prediction (Day-0 prediction support)

    /// Converts an athlete's PBs into target-race pace samples via
    /// Riegel formula (with Kilian's effective-km correction for
    /// trail). Returns weighted (pace, weight) tuples that plug into
    /// the same percentile pipeline as run-based paces — so the rest
    /// of the estimator works unchanged when only PBs are available.
    ///
    /// Weights blend three signals:
    /// - Recency (exponential decay, 180-day half-life — reuses
    ///   PersonalBest.recencyWeight)
    /// - Distance proximity (PB distance closer to target = higher
    ///   weight; far-extrapolated PBs are noisy)
    /// - Terrain match (road PB → road race = full weight; road PB
    ///   → trail race or trail PB → road race = 0.6 penalty because
    ///   the terrain-translation amplifies uncertainty)
    func pbsAsWeightedPaces(
        athlete: Athlete,
        race: Race,
        raceEffectiveKm: Double
    ) -> [(pace: Double, weight: Double)] {
        var result: [(Double, Double)] = []
        let raceFlatKm = race.distanceKm

        for pb in athlete.personalBests where pb.timeSeconds > 0 {
            let pbKm = pb.distance.distanceKm
            guard pbKm > 0 else { continue }
            let exponent = riegelExponent(toDistanceKm: raceFlatKm)
            let predictedTime = pb.timeSeconds * pow(raceFlatKm / pbKm, exponent)
            let pace = predictedTime / max(raceEffectiveKm, 1)
            let recency = pb.recencyWeight()
            let proximity = 1.0 / (1.0 + abs(pbKm - raceFlatKm) / max(raceFlatKm, 1))
            let terrainMatch: Double = race.raceType == .road ? 1.0 : 0.6
            result.append((pace, recency * proximity * terrainMatch))
        }

        for tpb in athlete.trailPersonalBests where tpb.timeSeconds > 0 {
            let pbEffective = tpb.distanceKm + (tpb.elevationGainM / 100.0)
            guard pbEffective > 0 else { continue }
            let exponent = riegelExponent(toDistanceKm: raceEffectiveKm)
            let predictedTime = tpb.timeSeconds * pow(raceEffectiveKm / pbEffective, exponent)
            let pace = predictedTime / max(raceEffectiveKm, 1)
            let recency = tpb.recencyWeight()
            let proximity = 1.0 / (1.0 + abs(pbEffective - raceEffectiveKm) / max(raceEffectiveKm, 1))
            let terrainMatch: Double = race.raceType == .trail ? 1.0 : 0.6
            result.append((pace, recency * proximity * terrainMatch))
        }
        return result
    }

    private func riegelExponent(toDistanceKm km: Double) -> Double {
        // Pete Riegel (1981) — exponent for race-time conversion.
        // Marathon+ uses higher exponent due to greater fatigue
        // accumulation (Canova, Galloway acknowledge this — k≈1.07
        // for marathon, ~1.08 for ultra).
        switch km {
        case ..<30:    return 1.06
        case ..<50:    return 1.07
        default:       return 1.08
        }
    }

    // MARK: - Range spread (race-class + data-quality)

    /// Race-day aleatory uncertainty as a fraction (e.g., 0.02 = ±2%).
    /// Coaching consensus: shorter races have less variability (heat /
    /// nutrition / pacing matter less); ultras are dominated by
    /// race-day execution variance. Calibrated against Pfizinger /
    /// Daniels for road and Koop / Roche / House & Johnston for trail.
    func aleatorySpread(race: Race) -> Double {
        if race.raceType == .road {
            switch race.distanceKm {
            case ..<8:       return 0.015  // 5K
            case ..<15:      return 0.02   // 10K
            case ..<30:      return 0.02   // HM
            default:         return 0.03   // Marathon
            }
        }
        // Trail / ultra
        switch race.distanceKm {
        case ..<35:      return 0.04   // Short trail
        case ..<60:      return 0.06   // 50K
        case ..<100:     return 0.08   // 50mi
        case ..<150:     return 0.10   // 100K
        case ..<220:     return 0.13   // 100mi
        default:         return 0.18   // Multi-day
        }
    }

    /// Epistemic uncertainty (how well we know athlete's fitness)
    /// for non-runs sources. Scales with availability + freshness of
    /// PBs (or zero for fallback). Not used for runs-source — that
    /// gets variance via percentile spread.
    func epistemicSpread(
        source: PredictionSource,
        athlete: Athlete,
        race: Race
    ) -> Double {
        switch source {
        case .runs:
            return 0  // already encoded in percentile spread
        case .experienceFallback:
            // No fitness signal at all — wide range. Coaches give
            // ±25-30% when prepping a generic-fitness profile.
            return 0.25
        case .personalBests:
            // Two factors: how MANY PBs and how MATCHED they are.
            let allPBs = athlete.personalBests.filter { $0.timeSeconds > 0 }
                .map { $0.recencyWeight() }
                + athlete.trailPersonalBests.filter { $0.timeSeconds > 0 }
                .map { $0.recencyWeight() }
            // Sum of recency weights → effective sample size. 2.0+ →
            // strong signal; 1.0 → moderate; <0.5 → weak (very old).
            let totalRecencyWeight = allPBs.reduce(0, +)
            let recencyComponent: Double
            switch totalRecencyWeight {
            case ..<0.5:    recencyComponent = 0.18  // weak / very old
            case ..<1.0:    recencyComponent = 0.12
            case ..<2.0:    recencyComponent = 0.08
            default:        recencyComponent = 0.05
            }
            // Distance-match: PBs at same race type get extra credit.
            let hasMatchingDistanceType = athlete.personalBests.contains { pb in
                pb.timeSeconds > 0 && race.raceType == .road
            } || athlete.trailPersonalBests.contains { tpb in
                tpb.timeSeconds > 0 && race.raceType == .trail
            }
            let typeMatchPenalty: Double = hasMatchingDistanceType ? 0 : 0.05
            return recencyComponent + typeMatchPenalty
        }
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

        guard let first = centers.first, let last = centers.last else { return 0 }
        if p <= first.position { return first.pace }
        if p >= last.position { return last.pace }

        for i in 1..<centers.count {
            if p <= centers[i].position {
                let prev = centers[i - 1]
                let curr = centers[i]
                let fraction = (p - prev.position) / (curr.position - prev.position)
                return prev.pace + fraction * (curr.pace - prev.pace)
            }
        }
        return last.pace
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
        var segments: [(effort: Double, elevationGain: Double, elevationLoss: Double, checkpoint: Checkpoint)] = []
        var previousDistanceKm = 0.0
        var previousElevationM = 0.0

        for checkpoint in sortedCheckpoints {
            let segmentDistance = checkpoint.distanceFromStartKm - previousDistanceKm
            let elevationChange = checkpoint.elevationM - previousElevationM
            let elevationGain = max(0, elevationChange)
            let elevationLoss = max(0, -elevationChange)
            let effort = segmentDistance + (elevationGain / 100.0)
            segments.append((effort, elevationGain, elevationLoss, checkpoint))
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
                segmentElevationLossM: segment.elevationLoss,
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
