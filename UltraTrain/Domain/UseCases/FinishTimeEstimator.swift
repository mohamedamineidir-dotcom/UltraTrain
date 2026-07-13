import Foundation

struct FinishTimeEstimator: EstimateFinishTimeUseCase, Sendable {

    private let mlPredictionService: (any FinishTimePredictionServiceProtocol)?

    init(mlPredictionService: (any FinishTimePredictionServiceProtocol)? = nil) {
        self.mlPredictionService = mlPredictionService
    }

    /// Re-exposed for internal use; the canonical type lives on
    /// `FinishPredictionSource` (Domain/Models/FinishEstimate.swift)
    /// so the UI layer can read it off the FinishEstimate without
    /// pulling in this estimator.
    typealias PredictionSource = FinishPredictionSource

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
        let raceEffectiveKm = mountainEffectiveKm(race)

        // Pace anchor: prefer recent runs; fall back to PBs (Riegel +
        // Kilian for trail); last resort is experience-level fallback.
        // Day-0 prediction is a first-class citizen: athletes get a
        // credible range from their PBs alone before logging any
        // training. The range widens as data quality decreases.
        //
        // Every signal is projected to the race's MOUNTAIN-effective
        // distance with endurance decay (Riegel), so a short/flat effort
        // is not naively assumed to hold over a far longer, far hillier
        // race. This is the fix for road-fast athletes getting absurdly
        // quick ultra predictions.
        var weightedPaces: [(pace: Double, weight: Double)] = []
        for run in recentRuns {
            let runEffectiveKm = mountainEffectiveKm(distanceKm: run.distanceKm, elevationGainM: run.elevationGainM)
            guard runEffectiveKm > 0, run.duration > 0 else { continue }
            let projected = projectedTime(timeSeconds: run.duration, fromEffectiveKm: runEffectiveKm, toEffectiveKm: raceEffectiveKm)
            let pace = projected / raceEffectiveKm
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

        // Course-difficulty calibration from real reference finish times
        // (last edition's winner / typical finisher), when the athlete
        // supplied them. Corrects what the physiological model can't infer
        // from distance + D+: technicality, altitude, heat, navigation.
        let referenceCal = referenceCourseCalibration(
            race: race, raceEffectiveKm: raceEffectiveKm, terrain: terrain, descent: descent
        )

        let algorithmicExpected = effectiveKm * medianPace * terrain * descent * form * ultra * calibration * weather * referenceCal

        // Source-dependent range. When we have runs, the percentile
        // spread (pace25 / pace75) already captures within-athlete
        // variance, combined with a small ±3-5% safety margin.
        // For PB / fallback predictions there's no run-level variance,
        // so we synthesise the spread from race-class aleatory
        // uncertainty (heat / GI / pacing variability) + epistemic
        // uncertainty (how well we know athlete's fitness from the
        // available signal). Asymmetric: things go wrong more often
        // than right, so the conservative side is wider.
        let experienceMultiplier = experienceSpreadMultiplier(athlete.experienceLevel)
        let optimisticTime: Double
        let conservativeTime: Double
        switch source {
        case .runs:
            // Fixed safety margin around the percentile spread. The
            // percentile spread itself already reflects this athlete's
            // real variance and isn't touched; only the flat margin
            // (originally ±3%/±5%) scales with experience.
            let optMargin = 0.03 * experienceMultiplier
            let conMargin = 0.05 * experienceMultiplier
            optimisticTime = effectiveKm * pace25 * terrain * descent * ultra * (1.0 - optMargin) * calibration * weather * referenceCal
            conservativeTime = effectiveKm * pace75 * terrain * descent * ultra * (1.0 + conMargin) * calibration * weather * referenceCal
        case .personalBests, .experienceFallback:
            let aleatoryPct = aleatorySpread(race: race)
            let epistemicPct = epistemicSpread(source: source, athlete: athlete, race: race)
            let totalSpread = (aleatoryPct * aleatoryPct + epistemicPct * epistemicPct).squareRoot() * experienceMultiplier
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
            hasRaceResults: raceResultsUsed > 0,
            source: source,
            athlete: athlete
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
            weatherImpactSummary: weatherImpact?.summary,
            predictionSource: source
        )
    }

    // MARK: - Race-day projection

    /// "What this athlete will likely be capable of on race day, after
    /// following a training plan" — as opposed to `expectedTime`, which is
    /// "what they could do if the race were today." Blends toward the
    /// optimistic scenario, since training between now and race day mostly
    /// closes the gap between current fitness and best-case fitness.
    ///
    /// The blend fraction scales with `weeksToRace`: a 4-week block barely
    /// moves the needle, a full 20+ week periodized cycle can close most of
    /// the gap to today's best-case fitness. Previously this was a flat 15%
    /// regardless of training window, so a 4-week and a 40-week prep showed
    /// the exact same projected improvement — which is why a 21-week ultra
    /// prep was projecting only ~10 minutes of gain on a 14+ hour race.
    ///
    /// Used both by `FinishTimeEvolutionView`'s no-goal fallback (so the
    /// projected curve and this number agree) and by goal-setting, so a
    /// "realistic target" suggestion is anchored to race-day potential
    /// rather than today's snapshot — the two must use the same formula
    /// or a recommended goal can look wrong later once the plan exists.
    ///
    /// `intensityMultiplier` (see `trainingIntensityMultiplier`) lets two
    /// athletes with identical current fitness and the same weeks to race
    /// project different outcomes depending on how hard they're actually
    /// training for THIS race — a higher multiplier pulls the blend
    /// further toward the optimistic scenario (more of the gap closed), a
    /// lower one keeps it closer to today's expected.
    static func projectedRaceDayEstimate(
        optimisticTime: TimeInterval,
        expectedTime: TimeInterval,
        weeksToRace: Int = 12,
        intensityMultiplier: Double = 1.0
    ) -> TimeInterval {
        let baseBlend = raceDayBlendFraction(weeksToRace: weeksToRace)
        let adjustedBlend = min(max(baseBlend / intensityMultiplier, 0.05), 0.95)
        return optimisticTime + (expectedTime - optimisticTime) * adjustedBlend
    }

    /// Scales how much of the weeks-based improvement potential is
    /// actually realized, based on how hard the athlete is training for
    /// this specific race. Two athletes with the same current fitness and
    /// the same race shouldn't project the same race-day time if one
    /// trains for enjoyment (reduced volume, more rest) and the other for
    /// performance (high volume/intensity) — the higher-intensity athlete
    /// has a genuinely higher adaptation ceiling by race day.
    static func trainingIntensityMultiplier(philosophy: TrainingPhilosophy, sessionsPerWeek: Int) -> Double {
        let base: Double
        switch philosophy {
        case .enjoyment:   base = 0.65
        case .balanced:    base = 1.0
        case .performance: base = 1.30
        }
        // Small extra adjustment around a 5-run/week baseline (Athlete's
        // own default), capped so it can't swing wider than the
        // philosophy tier itself.
        let sessionAdjustment = Double(sessionsPerWeek - 5) * 0.03
        return min(max(base + sessionAdjustment, 0.5), 1.5)
    }

    /// The blend fraction interpolates from `blendAtShortWindow` (little
    /// time to adapt, stay close to today's `expectedTime`) down to
    /// `blendAtLongWindow` (a full periodized cycle, close most of the gap
    /// to `optimisticTime`) — smaller blend = more of the optimistic
    /// scenario mixed in, since blend 0 returns exactly `optimisticTime`
    /// and blend 1 returns exactly `expectedTime`. Floors/ceilings keep
    /// this from producing an absurd "0 weeks = already there" or "1 year
    /// = instant elite" result; linear in between.
    private static func raceDayBlendFraction(weeksToRace: Int) -> Double {
        let minWeeks = 4.0, maxWeeks = 24.0
        let blendAtShortWindow = 0.60, blendAtLongWindow = 0.10
        let w = Double(max(0, weeksToRace))
        guard w > minWeeks else { return blendAtShortWindow }
        guard w < maxWeeks else { return blendAtLongWindow }
        let t = (w - minWeeks) / (maxWeeks - minWeeks)
        return blendAtShortWindow + (blendAtLongWindow - blendAtShortWindow) * t
    }

    // MARK: - Quick synchronous estimate

    /// Fitness-aware finish-time estimate without the full async pipeline
    /// (recent runs, weather, ML). Used to seed planned durations such as a
    /// B/C-race day session, where a generic experience-level default
    /// ("1h30 for any 10K") looks absurd next to a 37-minute PR.
    ///
    /// Order of preference:
    /// 1. Explicit goal time, when the athlete set one.
    /// 2. Projection from the athlete's PBs / VMA (Riegel + terrain), the
    ///    same signal the real estimator uses for its day-0 prediction.
    /// 3. Experience-level heuristic, only when there's no fitness signal.
    ///
    /// Mirrors the deterministic core of `execute` with form, calibration
    /// and weather held neutral at 1.0 (those need data this path lacks).
    static func quickEstimate(athlete: Athlete, race: Race) -> TimeInterval {
        if case .targetTime(let time) = race.goalType { return time }

        let estimator = FinishTimeEstimator()
        let effectiveKm = estimator.mountainEffectiveKm(race)
        let pbPaces = estimator.pbsAsWeightedPaces(
            athlete: athlete, race: race, raceEffectiveKm: effectiveKm
        )
        guard !pbPaces.isEmpty else {
            return race.estimatedDuration(experience: athlete.experienceLevel)
        }
        let medianPace = estimator.weightedPercentile(pbPaces, p: 0.5)
        let terrain = estimator.terrainMultiplier(race.terrainDifficulty)
        let descent = estimator.descentPenalty(race)
        let ultra = estimator.ultraFatigueMultiplier(
            experienceLevel: athlete.experienceLevel,
            raceDistanceKm: race.distanceKm
        )
        return effectiveKm * medianPace * terrain * descent * ultra
    }

    // MARK: - PB-based prediction (Day-0 prediction support)

    /// Converts an athlete's PBs into target-race pace samples via
    /// Riegel formula (with Kilian's effective-km correction for
    /// trail). Returns weighted (pace, weight) tuples that plug into
    /// the same percentile pipeline as run-based paces, so the rest
    /// of the estimator works unchanged when only PBs are available.
    ///
    /// Weights blend three signals:
    /// - Recency (exponential decay, 180-day half-life, reuses
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
            // Project the flat road PB straight to the mountain-effective
            // distance: the decay over that much larger distance is what
            // turns 10K-fast into a credible all-day mountain pace.
            let predictedTime = projectedTime(timeSeconds: pb.timeSeconds, fromEffectiveKm: pbKm, toEffectiveKm: raceEffectiveKm)
            let pace = predictedTime / max(raceEffectiveKm, 1)
            let recency = pb.recencyWeight()
            let proximity = 1.0 / (1.0 + abs(pbKm - raceFlatKm) / max(raceFlatKm, 1))
            let terrainMatch: Double = race.raceType == .road ? 1.0 : 0.6
            result.append((pace, recency * proximity * terrainMatch))
        }

        for tpb in athlete.trailPersonalBests where tpb.timeSeconds > 0 {
            let pbEffective = mountainEffectiveKm(distanceKm: tpb.distanceKm, elevationGainM: tpb.elevationGainM)
            guard pbEffective > 0 else { continue }
            let predictedTime = projectedTime(timeSeconds: tpb.timeSeconds, fromEffectiveKm: pbEffective, toEffectiveKm: raceEffectiveKm)
            let pace = predictedTime / max(raceEffectiveKm, 1)
            let recency = tpb.recencyWeight()
            let proximity = 1.0 / (1.0 + abs(pbEffective - raceEffectiveKm) / max(raceEffectiveKm, 1))
            let terrainMatch: Double = race.raceType == .trail ? 1.0 : 0.6
            result.append((pace, recency * proximity * terrainMatch))
        }

        // VMA from a fitness test is a measured-fitness signal that
        // wouldn't otherwise reach the predictor (it lives on the
        // athlete, not in personalBests). Convert to a 5K-equivalent
        // synthetic PB via Daniels (5K is run at ~97% vVO2max → 5K
        // pace ≈ (3600/VMA) × 1.02 sec/km). Discount the weight
        // slightly because it's derived not raced, race-day pacing
        // adds variance the test doesn't capture.
        if let vma = athlete.vmaKmh, vma > 0 {
            let fiveKPaceSecPerKm = (3600.0 / vma) * 1.02
            let fiveKTimeSec = fiveKPaceSecPerKm * 5
            let predictedTime = projectedTime(timeSeconds: fiveKTimeSec, fromEffectiveKm: 5.0, toEffectiveKm: raceEffectiveKm)
            let pace = predictedTime / max(raceEffectiveKm, 1)
            // Recency: VMA is by definition the most recent fitness
            // measurement (updated on each test). Weight = 1.0 fresh.
            let proximity = 1.0 / (1.0 + abs(5.0 - raceFlatKm) / max(raceFlatKm, 1))
            let terrainMatch: Double = race.raceType == .road ? 1.0 : 0.6
            let derivedDiscount = 0.8
            result.append((pace, proximity * terrainMatch * derivedDiscount))
        }
        return result
    }

    private func riegelExponent(toDistanceKm km: Double) -> Double {
        // Pete Riegel (1981), exponent for race-time conversion.
        // Marathon+ uses higher exponent due to greater fatigue
        // accumulation (Canova, Galloway acknowledge this, k≈1.07
        // for marathon, ~1.08 for ultra).
        switch km {
        case ..<30:    return 1.06
        case ..<50:    return 1.07
        default:       return 1.08
        }
    }

    // MARK: - Range spread (race-class + data-quality)

    /// Scales the optimistic/conservative spread by athlete experience.
    /// Real coaching variance is tighter for more experienced athletes —
    /// they're less exposed to the pacing/fueling/navigation mistakes
    /// that dominate variance for less experienced runners — so the same
    /// distance-based aleatory spread should not produce the same
    /// absolute range for a beginner and an elite athlete.
    func experienceSpreadMultiplier(_ level: ExperienceLevel) -> Double {
        switch level {
        case .beginner:     1.25
        case .intermediate: 1.05
        case .advanced:     0.85
        case .elite:        0.70
        }
    }

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
    /// PBs (or zero for fallback). Not used for runs-source, that
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
            // No fitness signal at all, wide range. Coaches give
            // ±25-30% when prepping a generic-fitness profile.
            return 0.25
        case .personalBests:
            // Two factors: how MANY signals and how MATCHED they are.
            // Include VMA as a fresh signal (weight 1.0) when present
            // a recent fitness test counts as a fitness anchor even
            // without explicit PBs.
            var allSignals = athlete.personalBests.filter { $0.timeSeconds > 0 }
                .map { $0.recencyWeight() }
                + athlete.trailPersonalBests.filter { $0.timeSeconds > 0 }
                .map { $0.recencyWeight() }
            if let vma = athlete.vmaKmh, vma > 0 {
                allSignals.append(0.8)  // fresh signal but slightly discounted
            }
            // Sum of recency weights → effective sample size. 2.0+ →
            // strong signal; 1.0 → moderate; <0.5 → weak (very old).
            // Bucket boundaries are slightly wider than the integer
            // counts to absorb microsecond drift in `Date.now`
            // a fresh PB returns recencyWeight ~ 0.99999... not exactly
            // 1.0, which would otherwise tip into the wrong bucket.
            let totalRecencyWeight = allSignals.reduce(0, +)
            let recencyComponent: Double
            switch totalRecencyWeight {
            case ..<0.5:    recencyComponent = 0.18  // weak / very old
            case ..<0.99:   recencyComponent = 0.12  // partially decayed single PB
            case ..<1.99:   recencyComponent = 0.08  // 1-2 fresh PBs
            default:        recencyComponent = 0.05  // multiple recent PBs
            }
            // Type match: a fitness signal in the right "domain"
            // (road or trail) earns no penalty. VMA counts as a
            // road-side signal, it's a flat-running fitness anchor.
            // For trail races, VMA still helps via terrainMatch in
            // pbsAsWeightedPaces, but it's not a perfect-match
            // signal so the penalty applies if no trail PB exists.
            let hasMatchingDistanceType: Bool = {
                if race.raceType == .road {
                    let hasRoadPB = athlete.personalBests.contains { $0.timeSeconds > 0 }
                    let hasVMA = (athlete.vmaKmh ?? 0) > 0
                    return hasRoadPB || hasVMA
                } else {
                    return athlete.trailPersonalBests.contains { $0.timeSeconds > 0 }
                }
            }()
            let typeMatchPenalty: Double = hasMatchingDistanceType ? 0 : 0.05
            return recencyComponent + typeMatchPenalty
        }
    }

    // MARK: - Mountain-effective distance & endurance projection

    /// Vertical-gain equivalence: ~80 m of climb costs about the *effort*
    /// of 1 extra flat km. This is deliberately heavier than the classic
    /// Kilian 100 m/km, but the decisive correction is not this constant —
    /// it is that we then project fitness to THIS larger distance with
    /// endurance decay (`projectedTime`). The previous model decayed the
    /// flat distance only and added the vertical term at full road pace,
    /// so 4500 m of climbing barely moved the prediction.
    static let climbMetersPerEquivalentKm = 80.0

    func mountainEffectiveKm(distanceKm: Double, elevationGainM: Double) -> Double {
        distanceKm + max(0, elevationGainM) / Self.climbMetersPerEquivalentKm
    }

    func mountainEffectiveKm(_ race: Race) -> Double {
        mountainEffectiveKm(distanceKm: race.distanceKm, elevationGainM: race.elevationGainM)
    }

    /// Riegel endurance-decay projection: a performance over
    /// `fromEffectiveKm` projected to `toEffectiveKm`. A longer target
    /// yields a disproportionately slower pace — the essence of why a
    /// road PR cannot be linearly stretched across an ultra.
    func projectedTime(timeSeconds: Double, fromEffectiveKm: Double, toEffectiveKm: Double) -> Double {
        guard fromEffectiveKm > 0, timeSeconds > 0 else { return timeSeconds }
        let exponent = riegelExponent(toDistanceKm: toEffectiveKm)
        return timeSeconds * pow(toEffectiveKm / fromEffectiveKm, exponent)
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

    // MARK: - Reference-time course calibration

    /// When the athlete supplies real reference finish times for this
    /// course (last edition's winner and/or a typical median finisher),
    /// calibrate the course's true difficulty against the model: "what
    /// would the model predict for a known-calibre runner here?" then
    /// scale by how the real field actually finished. This captures
    /// course-specific difficulty (technicality, altitude, heat,
    /// navigation, cumulative descent) that distance + D+ alone miss, and
    /// is exactly the race-data anchoring an ultra needs.
    ///
    /// Anchors are central road-fitness equivalents: a competitive
    /// front-runner (~31:00 10K) and a typical finisher (~52:00 10K). The
    /// median anchor is weighted higher (more stable, less dependent on a
    /// single exceptional individual). The factor is bounded so a
    /// mis-entered reference can't produce an absurd swing.
    func referenceCourseCalibration(
        race: Race,
        raceEffectiveKm: Double,
        terrain: Double,
        descent: Double
    ) -> Double {
        let winnerAnchorSeconds = 1860.0   // ~31:00 10K-equivalent front-runner
        let medianAnchorSeconds = 3120.0   // ~52:00 10K-equivalent typical finisher

        func modelTime(forAnchorSeconds anchor: Double) -> Double {
            projectedTime(timeSeconds: anchor, fromEffectiveKm: 10, toEffectiveKm: raceEffectiveKm) * terrain * descent
        }

        var weightedSum = 0.0
        var weightTotal = 0.0
        if let winner = race.referenceWinnerTimeSeconds, winner > 0 {
            let model = modelTime(forAnchorSeconds: winnerAnchorSeconds)
            if model > 0 { weightedSum += (winner / model) * 0.35; weightTotal += 0.35 }
        }
        if let median = race.referenceMedianTimeSeconds, median > 0 {
            let model = modelTime(forAnchorSeconds: medianAnchorSeconds)
            if model > 0 { weightedSum += (median / model) * 0.65; weightTotal += 0.65 }
        }
        guard weightTotal > 0 else { return 1.0 }
        let raw = weightedSum / weightTotal
        // Damp toward 1.0: the anchors are central assumptions, so let the
        // reference refine the model rather than override it. Then bound.
        let damped = 1.0 + (raw - 1.0) * 0.75
        return min(1.4, max(0.75, damped))
    }

    // MARK: - Confidence

    private func calculateConfidence(
        runs: [CompletedRun],
        fitness: FitnessSnapshot?,
        race: Race,
        hasRaceResults: Bool,
        source: PredictionSource? = nil,
        athlete: Athlete? = nil
    ) -> Double {
        var confidence = 40.0
        if runs.count > 5 { confidence += 10 }
        if runs.count > 10 { confidence += 10 }
        if fitness != nil { confidence += 10 }
        if runs.contains(where: { $0.distanceKm >= race.distanceKm * 0.5 }) { confidence += 15 }
        if runs.contains(where: { $0.elevationGainM >= 500 }) { confidence += 10 }
        if hasRaceResults { confidence += 15 }
        // PB-source bump: when no runs are available but we DO have
        // PBs / VMA from the fitness test, we still know SOMETHING
        // about the athlete's fitness. +10 lifts the confidence
        // label from "Low" to "Moderate", matches the badge's
        // "Early estimate from your profile data" framing rather
        // than the dismissive "low confidence, keep training"
        // copy that was designed for fully-uncalibrated athletes.
        if source == .personalBests {
            confidence += 10
            // Extra +5 if the athlete has multiple recent fitness
            // signals (PB + VMA, or PBs in matched type).
            if let athlete {
                let hasPB = !athlete.personalBests.filter { $0.timeSeconds > 0 }.isEmpty
                    || !athlete.trailPersonalBests.filter { $0.timeSeconds > 0 }.isEmpty
                let hasVMA = (athlete.vmaKmh ?? 0) > 0
                if hasPB && hasVMA { confidence += 5 }
            }
        }
        return min(confidence, 95)
    }
}
