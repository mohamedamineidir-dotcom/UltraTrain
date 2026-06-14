import Foundation

struct TrainingPlanGenerator: GenerateTrainingPlanUseCase {

    /// Optional run history source. When provided, the generator
    /// pulls the athlete's last 90 days of completed runs and feeds
    /// them into PersonalizationProfile so the plan anchor reflects
    /// **demonstrated** weekly capacity rather than the stale
    /// onboarding snapshot. Nil means we fall back to snapshot
    /// existing tests and any caller that doesn't wire this don't
    /// see a behaviour change.
    let runRepository: RunRepository?

    init(runRepository: RunRepository? = nil) {
        self.runRepository = runRepository
    }


    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan {
        try await execute(
            athlete: athlete,
            targetRace: targetRace,
            intermediateRaces: intermediateRaces,
            recentIntervalFeedback: []
        )
    }

    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race],
        recentIntervalFeedback: [IntervalPerformanceFeedback]
    ) async throws -> TrainingPlan {
        try await execute(
            athlete: athlete,
            targetRace: targetRace,
            intermediateRaces: intermediateRaces,
            recentIntervalFeedback: recentIntervalFeedback,
            planOptions: .standard
        )
    }

    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race],
        recentIntervalFeedback: [IntervalPerformanceFeedback],
        planOptions: PlanGenerationOptions
    ) async throws -> TrainingPlan {
        // Road race branch: completely separate pipeline, zero trail logic changes.
        if targetRace.raceType == .road {
            return try generateRoadPlan(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces,
                recentIntervalFeedback: recentIntervalFeedback,
                planOptions: planOptions
            )
        }

        let today = Date.now.startOfDay
        let raceDate = targetRace.date.startOfDay

        let totalWeeks = today.weeksBetween(raceDate)
        guard totalWeeks >= 4 else {
            throw DomainError.invalidTrainingPlan(
                reason: "Need at least 4 weeks before race day to generate a plan."
            )
        }

        // 1. Distribute phases (race-aware taper + race-distance peak shift)
        let taperProfile = TaperProfile.forRace(effectiveKm: targetRace.effectiveDistanceKm)
        let phases = PhaseDistributor.distribute(
            totalWeeks: totalWeeks,
            experience: athlete.experienceLevel,
            taperProfile: taperProfile,
            raceEffectiveKm: targetRace.effectiveDistanceKm
        )

        // 2. Build week skeletons (experience-based recovery cycle)
        let recoveryCycle = VolumeCapCalculator.recoveryCycle(
            for: athlete.experienceLevel,
            age: athlete.age
        )
        // Post-race recovery weeks. Daniels' rule: ~1 easy day per 3 km of
        // race distance. Translates to whole weeks:
        //   <30 km     → 1 week  (10K, HM)
        //   30-49 km   → 3 weeks (marathon, Pfitzinger AM Plan A reverse
        //                taper, Hansons Marathon Method Ch.10; marathon
        //                muscle damage takes 2-3 weeks to clear)
        //   50-99 km   → 3 weeks (50-100K)
        //   100-159 km → 4 weeks (100-mile range)
        //   160+ km    → 5 weeks (200K+, multi-day races warrant longest rebuild)
        // Athlete sees a structured return-to-training instead of falling
        // off the plan the day after their A-race.
        let postRaceRecoveryWeeks: Int
        switch targetRace.distanceKm {
        case ..<30:    postRaceRecoveryWeeks = 1
        case ..<50:    postRaceRecoveryWeeks = 3
        case ..<100:   postRaceRecoveryWeeks = 3
        case ..<160:   postRaceRecoveryWeeks = 4
        default:       postRaceRecoveryWeeks = 5
        }
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases,
            recoveryCycle: recoveryCycle,
            postRaceRecoveryWeeks: postRaceRecoveryWeeks
        )

        // 3. Compute intermediate race overrides BEFORE volume calculation
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces
        )

        // 3b. For volume calculation, clear isRecoveryWeek on override weeks
        // so that LongRunCurveCalculator doesn't double-reduce them with 0.65-0.75× multipliers.
        // The override templates control their own volume independently.
        let overrideWeekNumbers = Set(overrides.map(\.weekNumber))
        let volumeSkeletons = skeletons.map { skeleton in
            if overrideWeekNumbers.contains(skeleton.weekNumber) && skeleton.isRecoveryWeek {
                return WeekSkeletonBuilder.WeekSkeleton(
                    weekNumber: skeleton.weekNumber,
                    startDate: skeleton.startDate,
                    endDate: skeleton.endDate,
                    phase: skeleton.phase,
                    isRecoveryWeek: false,
                    phaseFocus: skeleton.phaseFocus
                )
            }
            return skeleton
        }

        // 4. Calculate volumes (with dynamic caps and anchoring)
        let raceDuration = targetRace.estimatedDuration(experience: athlete.experienceLevel)
        let raceEffectiveKm = targetRace.effectiveDistanceKm

        // Apply RecentFitnessChange anchor multiplier (asked in the
        // plan-time onboarding sheet). Athletes recovering from injury /
        // illness / extended time off shouldn't be anchored to the
        // pre-break weekly volume, early-prep weeks would prescribe
        // load they haven't built up to. Multiplier ranges 0.70-1.00
        // depending on severity. Default 1.00 = no change.
        let anchorMultiplier = planOptions.recentFitnessChange?.anchorMultiplier ?? 1.0
        let anchoredWeeklyVolumeKm = athlete.weeklyVolumeKm * anchorMultiplier

        // Build per-athlete personalization profile. Tenure, weight band,
        // ultra finish count, demonstrated longest run, and demonstrated
        // recent peak weekly volume feed into multipliers + hard caps.
        // Composite multiplier is clamped to [0.75, 1.30] inside the
        // profile so no single signal can blow up prescriptions.
        let ultraCount = countUltraFinishes(athlete: athlete)
        let recentRuns = await fetchRecentRuns(for: athlete)
        let personalization = PersonalizationProfile.from(
            athlete: athlete,
            ultraFinishCount: ultraCount,
            recentRuns: recentRuns
        )

        let volumes = VolumeCalculator.calculate(
            skeletons: volumeSkeletons,
            currentWeeklyVolumeKm: anchoredWeeklyVolumeKm,
            raceDistanceKm: targetRace.distanceKm,
            raceElevationGainM: targetRace.elevationGainM,
            experience: athlete.experienceLevel,
            philosophy: athlete.trainingPhilosophy,
            raceGoal: targetRace.goalType,
            raceDurationSeconds: raceDuration,
            raceEffectiveKm: raceEffectiveKm,
            preferredRunsPerWeek: athlete.preferredRunsPerWeek,
            raceType: targetRace.raceType,
            painFrequency: athlete.painFrequency,
            taperProfile: taperProfile,
            athleteAge: athlete.age,
            personalization: personalization
        )

        // 5. Track week number within each phase
        let phaseCounters = computeWeekNumbersInPhase(skeletons: skeletons)

        // 5b. Detect the A-race week (the week whose date range contains
        // targetRace.date). For that week we bypass the standard phase
        // templates and dispatch to the research-backed
        // TrailRaceWeekTemplates builder, so race day appears in the plan
        // as a `.race` session and the prep shape adapts to distance
        // class + mountain profile + experience + philosophy.
        let aRaceWeekIdx = skeletons.firstIndex { skeleton in
            raceDate >= skeleton.startDate && raceDate <= skeleton.endDate
        }

        // 5c. Mid-prep fitness test schedule (opt-in via planOptions).
        // Trail pipeline skips the test entirely for races ≥100K, Koop
        // and House & Johnston both argue VMA-style tests are misleading
        // for ultras. Below 100K, the variant adapts to athlete's terrain
        // (verticalGainEnvironment + uphillDuration), sustained 30-min
        // uphill TT for mountain athletes, 4×8 / 5×4 repeats for athletes
        // with shorter hills, treadmill incline, or 6-min VMA flat as
        // fallback.
        let fitnessTestSchedule = FitnessTestScheduler.schedule(
            skeletons: skeletons,
            targetRace: targetRace,
            athlete: athlete,
            userOptIn: planOptions.includeFitnessTest,
            existingOverrides: overrides,
            tuneUpWeekNumber: nil,
            fitnessCheckInWeeks: []
        )

        // 5d. B/C-race specificity injections (opt-in per race via
        // Race.includesSpecificPrep). When the athlete has a road B/C
        // race with a target time AND opted in, inject 1-3 race-pace
        // sessions in the 2-3 weeks before the race. Replaces existing
        // intervals/tempo/longRun slots, no net fatigue. See
        // BRaceSpecificityCalculator for the coaching basis.
        let bRaceSpecificityInjections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces,
            targetRace: targetRace,
            athlete: athlete
        )

        // 6. Generate sessions for each week
        var allWorkouts: [IntervalWorkout] = []
        var allStrengthWorkouts: [StrengthWorkout] = []

        // Build strength config if athlete opted in
        let wantsStrength = athlete.strengthTrainingPreference == .yes

        let weeks: [TrainingWeek] = zip(skeletons, volumes).enumerated().map { index, pair in
            let (skeleton, volume) = pair
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }

            let strengthConfig: StrengthSessionGenerator.Config? = wantsStrength
                ? .init(
                    experience: athlete.experienceLevel,
                    phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                    location: athlete.strengthTrainingLocation,
                    painFrequency: athlete.painFrequency,
                    injuryCount: athlete.injuryCountLastYear,
                    hasRecentInjury: athlete.hasRecentInjury,
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    weekNumberInPhase: phaseCounters[index],
                    isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                    raceEffectiveKm: raceEffectiveKm,
                    raceType: targetRace.raceType
                )
                : nil

            let qualityRatio = QualitySessionRatioResolver.resolve(
                raceType: targetRace.raceType,
                intervalFocus: athlete.intervalFocus,
                phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                weekNumberInPhase: phaseCounters[index],
                raceElevationGainM: targetRace.elevationGainM,
                raceDistanceKm: targetRace.distanceKm
            )

            // Build race context for intermediate race overrides.
            // B2: include the race's day-of-week so bRaceWeekTemplates /
            // cRaceWeekTemplates can place the .race session on the actual
            // race date instead of defaulting to Saturday.
            let intermediateRaceContext: SessionTemplateGenerator.RaceContext?
            if let raceId = override?.raceId,
               let intRace = intermediateRaces.first(where: { $0.id == raceId }) {
                let cal = Calendar.current
                let weekStartDay = cal.startOfDay(for: skeleton.startDate)
                let raceDayStart = cal.startOfDay(for: intRace.date)
                let dayDiff = cal.dateComponents([.day], from: weekStartDay, to: raceDayStart).day ?? 5
                let raceDayOffset = max(0, min(6, dayDiff))
                intermediateRaceContext = .init(
                    name: intRace.name,
                    distanceKm: intRace.distanceKm,
                    elevationGainM: intRace.elevationGainM,
                    estimatedDurationSeconds: FinishTimeEstimator.quickEstimate(athlete: athlete, race: intRace),
                    goalType: intRace.goalType,
                    dayOffset: raceDayOffset
                )
            } else {
                intermediateRaceContext = nil
            }

            // Heat-acclimation flag, true when forecasted race-day weather
            // is hot enough to demand pre-race adaptation (10-14 days of
            // heat exposure pre-race confers most of the benefit). Same
            // threshold the road generator uses.
            let trailHotRaceForecast: Bool = {
                guard let fc = targetRace.forecastedWeather else { return false }
                return fc.temperatureCelsius >= 22 || fc.humidity >= 65
            }()

            // Descent-heavy flag, drives the eccentric / quad-tolerance
            // cue on long runs and B2B day 2 in build/peak. Threshold
            // ≥1500m D- catches UTMB (10000m), Hardrock (10000m), TDS
            // (7000m), Madeira Sky (5000m), and similar mountain races
            // where descent is the limiter most athletes underprepare.
            // Also fires when descent density (D-/km) is ≥30 m/km even
            // at lower total D-, small-but-steep races.
            let isDescentHeavyRace: Bool = {
                guard targetRace.raceType == .trail else { return false }
                if targetRace.elevationLossM >= 1500 { return true }
                if targetRace.distanceKm > 0,
                   targetRace.elevationLossM / targetRace.distanceKm >= 30 {
                    return true
                }
                return false
            }()

            // A-race week + post-race recovery dispatch. Both bypass
            // the standard phase / recovery / override templates by
            // supplying pre-built session lists.
            //
            // - A-race week → TrailRaceWeekTemplates (race day shows
            //   up as a `.race` session; prep days adapt to distance /
            //   mountain profile / experience / philosophy)
            // - Post-race recovery weeks → TrailRaceRecoveryTemplates
            //   (volume drops sharply: 100mi W1 ≈ 5% of peak, with
            //   cross-training prescribed over running for the first
            //   two weeks of demanding races and for mountain profiles)
            let aRaceWeekTemplates: [SessionTemplateGenerator.SessionTemplate]?
            if index == aRaceWeekIdx {
                aRaceWeekTemplates = TrailRaceWeekTemplates.sessions(
                    targetRace: targetRace,
                    experience: athlete.experienceLevel,
                    philosophy: athlete.trainingPhilosophy,
                    weekStartDate: skeleton.startDate,
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek
                )
            } else if let aIdx = aRaceWeekIdx,
                      index > aIdx,
                      skeleton.isRecoveryWeek {
                let weekInRecovery = index - aIdx  // 1, 2, 3, 4, 5
                aRaceWeekTemplates = TrailRaceRecoveryTemplates.sessions(
                    targetRace: targetRace,
                    experience: athlete.experienceLevel,
                    philosophy: athlete.trainingPhilosophy,
                    weekStartDate: skeleton.startDate,
                    weekInRecovery: weekInRecovery
                )
            } else {
                aRaceWeekTemplates = nil
            }

            let result = SessionTemplateGenerator.sessions(
                for: skeleton,
                volume: volume,
                experience: athlete.experienceLevel,
                raceEffectiveKm: raceEffectiveKm,
                raceElevationGainM: targetRace.elevationGainM,
                totalWeeks: totalWeeks,
                philosophy: athlete.trainingPhilosophy,
                weekNumberInPhase: phaseCounters[index],
                raceOverride: override,
                preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                verticalGainEnvironment: athlete.verticalGainEnvironment,
                expectedRaceDuration: raceDuration,
                strengthConfig: strengthConfig,
                qualityRatio: qualityRatio,
                intervalFocus: athlete.intervalFocus,
                isRoadRace: targetRace.raceType == .road,
                intermediateRaceContext: intermediateRaceContext,
                isHotRaceForecast: trailHotRaceForecast,
                isDescentHeavyRace: isDescentHeavyRace,
                raceMaxElevationM: targetRace.maxElevationM,
                racePolesAllowed: targetRace.polesAllowed,
                restingHR: athlete.restingHeartRate,
                maxHR: athlete.maxHeartRate,
                biologicalSex: athlete.biologicalSex,
                athleteAge: athlete.age,
                aRaceWeekTemplates: aRaceWeekTemplates
            )

            // Apply terrain constraint adaptation for VG sessions (trail/ultra only)
            let adapted: VerticalGainConstraintAdapter.AdaptedResult
            if targetRace.raceType == .trail {
                let vgConfig = VerticalGainConstraintAdapter.Config(
                    environment: athlete.verticalGainEnvironment,
                    maxUphillSeconds: athlete.uphillDuration?.maxSeconds,
                    phase: skeleton.phase,
                    experience: athlete.experienceLevel
                )
                adapted = VerticalGainConstraintAdapter.adapt(
                    sessions: result.sessions,
                    workouts: result.workouts,
                    strengthWorkouts: result.strengthWorkouts,
                    config: vgConfig
                )
            } else {
                adapted = .init(
                    sessions: result.sessions,
                    workouts: result.workouts,
                    strengthWorkouts: result.strengthWorkouts,
                    planNote: nil
                )
            }

            allWorkouts.append(contentsOf: adapted.workouts)
            allStrengthWorkouts.append(contentsOf: adapted.strengthWorkouts)

            // Round endurance sessions (Long Run, Base Endurance,
            // Back-to-Back) to the nearest 5 minutes so the schedule
            // reads cleanly. Quality sessions stay at minute precision
            // their structure is minute-anchored.
            var roundedSessions = adapted.sessions
            EnduranceDurationRounder.roundInPlace(&roundedSessions)

            // Mid-prep fitness test substitution. When this week is
            // the scheduled test week, replace the first quality slot
            // (intervals → tempo) with the test session. Same pattern
            // as the periodic 2K check-in / Pfitz tune-up, a test is
            // a workout substitution, not an addition.
            if let schedule = fitnessTestSchedule,
               schedule.weekNumber == skeleton.weekNumber {
                substituteFitnessTest(
                    sessions: &roundedSessions,
                    variant: schedule.variant,
                    allWorkouts: &allWorkouts
                )
            }

            // B/C-race specificity injections for this week. Multiple
            // injections per week are possible if two races' prep
            // windows overlap; substitutor checks the slot type so
            // they don't trample each other (intervals vs tempo vs
            // longRun).
            let weekInjections = bRaceSpecificityInjections.filter {
                $0.weekNumber == skeleton.weekNumber
            }
            for injection in weekInjections {
                if let workout = BRaceSpecificitySubstitutor.apply(
                    injection: injection,
                    sessions: &roundedSessions,
                    athlete: athlete
                ) {
                    allWorkouts.append(workout)
                }
            }

            // Always recompute weekly duration from the actual session
            // content. Sessions' plannedDuration now reflects the
            // workout's real structure (warmup + work + cooldown for
            // intervals/tempo/VG, full long-run length, etc.) thanks
            // to the SessionTemplateGenerator alignment AND the
            // 5-min rounding above, so summing them gives the truth.
            // The volume.targetDurationSeconds budget is the planner's
            // INTENT before the workout engine got involved, keeping
            // it would make the chart disagree with the session list.
            let weekDuration = roundedSessions
                .filter { $0.type != .rest && $0.type != .strengthConditioning }
                .reduce(0) { $0 + $1.plannedDuration }

            // A-race week beats override label (B-race override would be
            // odd here anyway, but be defensive). targetVolumeKm and
            // targetElevationGainM get recomputed from the actual session
            // list whenever we used pre-built templates (A-race week or
            // post-race recovery), so the weekly card / chart reflects
            // what we generated.
            let isARace = (index == aRaceWeekIdx)
            let isPostRaceRecovery = aRaceWeekTemplates != nil && !isARace
            let usedPrebuilt = isARace || isPostRaceRecovery

            let weekPhase: TrainingPhase
            if isARace {
                weekPhase = .race
            } else if override?.behavior.isRaceWeek == true {
                weekPhase = .race
            } else {
                weekPhase = skeleton.phase
            }

            let weekVolumeKm: Double
            let weekElevationGainM: Double
            if usedPrebuilt {
                weekVolumeKm = roundedSessions
                    .filter { $0.type != .rest && $0.type != .strengthConditioning }
                    .reduce(0) { $0 + $1.plannedDistanceKm }
                weekElevationGainM = roundedSessions
                    .filter { $0.type != .rest && $0.type != .strengthConditioning }
                    .reduce(0) { $0 + $1.plannedElevationGainM }
            } else {
                weekVolumeKm = volume.targetVolumeKm
                weekElevationGainM = volume.targetElevationGainM
            }

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: weekPhase,
                sessions: roundedSessions,
                isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                targetVolumeKm: weekVolumeKm,
                targetElevationGainM: weekElevationGainM,
                targetDurationSeconds: weekDuration,
                phaseFocus: skeleton.phaseFocus
            )
        }

        let snapshots = intermediateRaces.map { race in
            RaceSnapshot(id: race.id, date: race.date, priority: race.priority)
        }

        var plan = TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            createdAt: .now,
            weeks: Self.applyPreRaceSpilloverTaper(weeks, raceDate: raceDate),
            intermediateRaceIds: intermediateRaces.map(\.id),
            intermediateRaceSnapshots: snapshots
        )
        plan.workouts = allWorkouts
        plan.strengthWorkouts = allStrengthWorkouts

        return plan
    }

    // MARK: - Road Race Plan Generation

    private func generateRoadPlan(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race],
        recentIntervalFeedback: [IntervalPerformanceFeedback] = [],
        planOptions: PlanGenerationOptions = .standard
    ) throws -> TrainingPlan {
        let today = Date.now.startOfDay
        let raceDate = targetRace.date.startOfDay
        let totalWeeks = today.weeksBetween(raceDate)

        guard totalWeeks >= 4 else {
            throw DomainError.invalidTrainingPlan(
                reason: "Need at least 4 weeks before race day to generate a plan."
            )
        }

        let discipline = RoadRaceDiscipline.from(distanceKm: targetRace.distanceKm)

        // 1. Road-specific taper profile
        let taperProfile = TaperProfile.forRoadRace(distanceKm: targetRace.distanceKm)

        // 2. Road-specific phase distribution
        let phases = RoadPhaseDistributor.distribute(
            totalWeeks: totalWeeks,
            experience: athlete.experienceLevel,
            raceDistanceKm: targetRace.distanceKm,
            taperProfile: taperProfile
        )

        // 3. Build week skeletons, road-specific recovery cycle
        let recoveryCycle = VolumeCapCalculator.roadRecoveryCycle(for: athlete.experienceLevel, discipline: discipline)
        // Post-race recovery weeks (same Daniels rule as trail). 10K and
        // HM get 1 week; marathon gets 2.
        let postRaceRecoveryWeeks: Int
        switch targetRace.distanceKm {
        case ..<30:    postRaceRecoveryWeeks = 1
        case ..<50:    postRaceRecoveryWeeks = 2
        default:       postRaceRecoveryWeeks = 3
        }
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases,
            recoveryCycle: recoveryCycle,
            postRaceRecoveryWeeks: postRaceRecoveryWeeks
        )

        // 4. Road-specific volume calculation. Apply RecentFitnessChange
        // anchor multiplier so athletes recovering from injury / illness
        // / time off don't get pre-break volume prescribed in early weeks.
        let anchorMultiplier = planOptions.recentFitnessChange?.anchorMultiplier ?? 1.0
        var anchoredAthlete = athlete
        anchoredAthlete.weeklyVolumeKm = athlete.weeklyVolumeKm * anchorMultiplier
        let volumes = RoadVolumeCalculator.calculate(
            skeletons: skeletons,
            athlete: anchoredAthlete,
            raceDistanceKm: targetRace.distanceKm,
            taperProfile: taperProfile,
            raceGoal: targetRace.goalType,
            preferredRunsPerWeek: athlete.preferredRunsPerWeek
        )

        // 5. Intermediate race overrides (reuse existing handler)
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces
        )

        // 6. Compute pace profile for session descriptions.
        //
        // RR-6: `.targetRanking` was silently falling through to `nil`, which
        // meant ranking-focused athletes got fitness-derived paces identical
        // to a `.finish` runner. We don't have field-of-runners data to look
        // up "what top 20 runs at this race", so we derive a stretch time
        // from the athlete's current fitness (7% faster than the experience
        // heuristic). Predictable, safe, coach-appropriate.
        let goalTime: TimeInterval?
        switch targetRace.goalType {
        case .targetTime(let time):
            goalTime = time
        case .targetRanking:
            let baseDuration = targetRace.estimatedDuration(experience: athlete.experienceLevel)
            goalTime = baseDuration * 0.93
        case .finish:
            goalTime = nil
        }
        let basePaceProfile = RoadPaceCalculator.paceProfile(
            goalTime: goalTime,
            raceDistanceKm: targetRace.distanceKm,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel,
            adaptiveFitness5KSeconds: athlete.adaptiveFitness5KSeconds,
            comebackPaceFactor: athlete.currentComebackPaceFactor()
        )

        // IR-2: blend in recent per-rep feedback to adjust target paces.
        // When the athlete has been hitting intervals at unsustainable RPE
        // or bailing on reps, the target slows; when they're clearing work
        // with headroom, it quickens. Rules in
        // RefineRoadPaceFromFeedbackUseCase, evidence-gated (≥3 in 21d),
        // phase-capped (base ±2%, build ±4%, peak ±5%, taper locked),
        // experience- and distance-dampened, hard-capped at ±8%. The
        // summary is threaded into coach advice so the athlete sees why
        // the target changed.
        let (paceProfile, refinementSummary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: basePaceProfile,
            feedback: recentIntervalFeedback,
            raceDate: raceDate,
            discipline: discipline,
            experience: athlete.experienceLevel
        )

        // 7. Phase counters
        let phaseCounters = computeWeekNumbersInPhase(skeletons: skeletons)

        // 7b. Detect the A-race week (week containing targetRace.date).
        // For that week we dispatch to RoadRaceWeekTemplates instead of
        // the normal RoadSessionSelector, so race day shows up as a
        // `.race` session with athlete-expected duration and prep days
        // follow Pfitzinger / Daniels / Hudson distance-class shapes
        // (5K → marathon).
        let aRaceWeekIdx = skeletons.firstIndex { skeleton in
            raceDate >= skeleton.startDate && raceDate <= skeleton.endDate
        }

        // RR-18: auto-insert a tune-up time-trial in a coach-appropriate
        // week when the athlete has no B-race nearby. Pfitzinger prescribes
        // a tune-up race at week -5 for marathon, week -3 for HM. Our
        // insertion targets the week BEFORE the taper starts (less 1 for
        // HM, less 2 for marathon), skipped entirely for 10K (too short).
        // If a B-race override already falls within ±1 week of the target,
        // we skip auto-insertion, athlete already has a sharpening race.
        let tuneUpWeekNumber = computeTuneUpWeekNumber(
            skeletons: skeletons,
            taperProfile: taperProfile,
            discipline: discipline,
            existingOverrides: overrides
        )

        // #28: periodic fitness check-ins (2K TTs) inserted through
        // base + build so the pace targets stay anchored to real
        // fitness as the athlete improves. Skips the tune-up window.
        let fitnessCheckInWeeks = PlanFitnessCheckIn.checkInWeekNumbers(
            skeletons: skeletons,
            tuneUpWeekNumber: tuneUpWeekNumber
        )

        // Mid-prep fitness test (opt-in). Coordinates with the auto
        // Pfitz tune-up + periodic 2K check-ins so we don't double-up
        // on hard tests. Variant is 6-min VMA flat (5K/10K races) or
        // 5K TT (HM/Marathon).
        let fitnessTestSchedule = FitnessTestScheduler.schedule(
            skeletons: skeletons,
            targetRace: targetRace,
            athlete: athlete,
            userOptIn: planOptions.includeFitnessTest,
            existingOverrides: overrides,
            tuneUpWeekNumber: tuneUpWeekNumber,
            fitnessCheckInWeeks: fitnessCheckInWeeks
        )

        // RR-20: first-timer flag, true when the athlete has no prior PB at
        // the race distance. Drives tactical coach advice on peak/taper long
        // runs ("hold back, finish strong, save the fast time for race #2").
        let isFirstTimer = isFirstTimerAtDistance(
            personalBests: athlete.personalBests,
            discipline: discipline
        )

        // RR-21: short-prep flag, true when the plan has fewer weeks than
        // research-accepted minimums (marathon: 12, HM: 8, 10K: 6). Drives
        // a coach-advice warning on base-phase long runs so the athlete can
        // still reconsider the target or defer.
        let shortPrepThreshold: Int
        switch discipline {
        case .road5K, .road10K: shortPrepThreshold = 6
        case .roadHalf:     shortPrepThreshold = 8
        case .roadMarathon: shortPrepThreshold = 12
        }
        let isShortPrep = totalWeeks < shortPrepThreshold

        // RR-22: hot-race flag. Triggered when the race has a forecasted
        // weather snapshot with temperature >= 22 °C or humidity >= 65%.
        // Drives a practical heat-acclimation advisory on peak/taper long
        // runs + tempo sessions. Advisory only, no training-plan changes
        // (we can't prescribe "run in 30 °C" to someone in a cold climate).
        let hotRaceForecast: Bool
        if let fc = targetRace.forecastedWeather {
            hotRaceForecast = fc.temperatureCelsius >= 22 || fc.humidity >= 65
        } else {
            hotRaceForecast = false
        }

        // 8. Generate sessions for each week
        var allWorkouts: [IntervalWorkout] = []
        var allStrengthWorkouts: [StrengthWorkout] = []

        // RR-5: Road athletes who opted into strength training need S&C
        // sessions on the plan. Previously the road branch never called
        // StrengthSessionGenerator, so opted-in athletes got zero strength
        // work in their plan. Same Config shape as the trail pipeline.
        let wantsStrength = athlete.strengthTrainingPreference == .yes

        let raceEffectiveKm = targetRace.distanceKm + (targetRace.elevationGainM / 100.0)

        // RR-33: quality-session variety state. `qualityOrdinal` is the
        // per-category progression coordinate (recovery weeks don't advance
        // it, so the build resumes after a deload); `usedQualitySignatures`
        // guarantees no two quality sessions in the plan share a work part.
        var qualityOrdinal: [RoadIntervalLibrary.Category: Int] = [:]
        var usedQualitySignatures: Set<String> = []
        // Per-(athlete, race) phase offset for rep-length menus and shape
        // rotation, so two similar athletes — and the same athlete's NEXT
        // prep (a new race) — get different structures for the same dose
        // (8×1K vs 4×2K). Stable for a given prep: regenerating the same
        // (athlete, race) reproduces the same plan.
        let qualityVarietySeed = Self.stableSeed(athlete.id, targetRace.id)

        let weeks: [TrainingWeek] = zip(skeletons, volumes).enumerated().map { index, pair in
            let (skeleton, volume) = pair
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }
            let isARaceWeek = (index == aRaceWeekIdx)
            // Post-race recovery week index (1-based: 1, 2, 3) when the
            // skeleton lands AFTER the A-race week and is flagged as a
            // recovery week by WeekSkeletonBuilder. Drives dispatch to
            // RoadRaceRecoveryTemplates so volume drops to ~10-20% of
            // peak in W1 instead of the in-plan recovery template's
            // ~60-70%.
            let postRaceRecoveryWeekN: Int? = {
                guard let aIdx = aRaceWeekIdx,
                      index > aIdx,
                      skeleton.isRecoveryWeek
                else { return nil }
                return index - aIdx
            }()

            let sessions: [TrainingSession]
            if isARaceWeek {
                // A-race week: RoadRaceWeekTemplates places the race day
                // as a `.race` session. Coach advice is generated by
                // RoadCoachAdviceGenerator so road tone (paces, glycogen
                // cues, race execution language) matches the rest of
                // the plan.
                let templates = RoadRaceWeekTemplates.sessions(
                    targetRace: targetRace,
                    experience: athlete.experienceLevel,
                    philosophy: athlete.trainingPhilosophy,
                    weekStartDate: skeleton.startDate,
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek
                )

                // B6: same fix as the B-race override path. A-race week
                // prep days (intervals / tempo race-pace tune-ups) need
                // structured IntervalWorkouts attached so the detail page
                // renders the phase cards instead of just the description.
                let aRaceQ1Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 0, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    isFirstTimerAtDistance: isFirstTimer
                )
                let aRaceQ2Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 1, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    excludeCategory: aRaceQ1Template?.category,
                    isFirstTimerAtDistance: isFirstTimer
                )
                let aRaceQ1Workout = aRaceQ1Template.map {
                    RoadWorkoutBuilder.build(
                        from: $0, paceProfile: paceProfile,
                        experience: athlete.experienceLevel, athleteAge: athlete.age
                    )
                }
                let aRaceQ2Workout = aRaceQ2Template.map {
                    RoadWorkoutBuilder.build(
                        from: $0, paceProfile: paceProfile,
                        experience: athlete.experienceLevel, athleteAge: athlete.age
                    )
                }
                if let w = aRaceQ1Workout { allWorkouts.append(w) }
                if let w = aRaceQ2Workout { allWorkouts.append(w) }

                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(
                        template: tpl, skeleton: skeleton,
                        dayIndex: dayIdx, volume: volume
                    )
                    session.plannedElevationGainM = 0
                    if tpl.type == .race {
                        session.isKeySession = true
                        session.coachAdvice = roadRaceDayCoachAdvice(
                            discipline: discipline,
                            paceProfile: paceProfile,
                            isFirstTimer: isFirstTimer,
                            hotRaceForecast: hotRaceForecast
                        )
                    } else if tpl.type == .intervals, let w = aRaceQ1Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = aRaceQ1Template?.category.displayName
                        alignSessionWithWorkout(&session, workout: w)
                    } else if tpl.type == .tempo, let w = aRaceQ2Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = aRaceQ2Template?.category.displayName
                        alignSessionWithWorkout(&session, workout: w)
                    }
                    if tpl.type != .race && tpl.type != .rest {
                        session.coachAdvice = RoadCoachAdviceGenerator.advice(
                            type: tpl.type, intensity: tpl.intensity,
                            phase: .race, discipline: discipline,
                            isRecoveryWeek: false,
                            paceProfile: paceProfile,
                            raceName: targetRace.name,
                            experience: athlete.experienceLevel,
                            isFirstTimer: isFirstTimer,
                            isShortPrep: isShortPrep,
                            hotRaceForecast: hotRaceForecast,
                            refinementSummary: refinementSummary,
                            restingHR: athlete.restingHeartRate,
                            maxHR: athlete.maxHeartRate,
                            biologicalSex: athlete.biologicalSex,
                            qualityTemplate: nil
                        )
                    }
                    return session
                }
            } else if let weekInRecovery = postRaceRecoveryWeekN {
                // Post-race recovery: RoadRaceRecoveryTemplates dispatch
                // by distance class + week. Volume falls sharply (W1
                // ≈ 15-20% of peak for marathon) and cross-training
                // appears in marathon W1 / ultra-road W1 prescriptions.
                let templates = RoadRaceRecoveryTemplates.sessions(
                    targetRace: targetRace,
                    experience: athlete.experienceLevel,
                    philosophy: athlete.trainingPhilosophy,
                    weekStartDate: skeleton.startDate,
                    weekInRecovery: weekInRecovery
                )
                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(
                        template: tpl, skeleton: skeleton,
                        dayIndex: dayIdx, volume: volume
                    )
                    session.plannedElevationGainM = 0
                    // Description carries the recovery cue; coachAdvice
                    // stays nil to keep the row clean.
                    return session
                }
            } else if let override {
                // Use existing override templates for intermediate race weeks
                let intermediateRaceContext: SessionTemplateGenerator.RaceContext?
                let raceId = override.raceId
                if let intRace = intermediateRaces.first(where: { $0.id == raceId }) {
                    // B2: compute the race day relative to the week's start
                    // so the .race session lands on the actual race date
                    // (e.g. Sunday) instead of the hardcoded Saturday slot
                    // the legacy templates used.
                    let cal = Calendar.current
                    let weekStartDay = cal.startOfDay(for: skeleton.startDate)
                    let raceDayStart = cal.startOfDay(for: intRace.date)
                    let dayDiff = cal.dateComponents([.day], from: weekStartDay, to: raceDayStart).day ?? 5
                    let raceDayOffset = max(0, min(6, dayDiff))
                    intermediateRaceContext = .init(
                        name: intRace.name, distanceKm: intRace.distanceKm,
                        elevationGainM: intRace.elevationGainM,
                        estimatedDurationSeconds: FinishTimeEstimator.quickEstimate(athlete: athlete, race: intRace),
                        goalType: intRace.goalType,
                        dayOffset: raceDayOffset
                    )
                } else {
                    intermediateRaceContext = nil
                }
                let templates = SessionTemplateGenerator.overrideTemplates(
                    for: override.behavior, volume: volume,
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    raceContext: intermediateRaceContext,
                    isRoadRace: true  // RR-4: strip VG sessions + elevation from road B-race weeks
                )

                // B6: Build structured IntervalWorkouts for the race-week
                // opener intervals/tempo sessions so SessionDetailView
                // renders the phase-breakdown cards (warm-up / work /
                // recovery / cool-down). Without this, the override path
                // produced sessions with `intervalWorkoutId == nil` and
                // the athlete only ever saw the prose description.
                let openerQ1Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 0, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    isFirstTimerAtDistance: isFirstTimer
                )
                let openerQ2Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 1, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    excludeCategory: openerQ1Template?.category,
                    isFirstTimerAtDistance: isFirstTimer
                )
                let openerQ1Workout = openerQ1Template.map {
                    RoadWorkoutBuilder.build(
                        from: $0, paceProfile: paceProfile,
                        experience: athlete.experienceLevel, athleteAge: athlete.age
                    )
                }
                let openerQ2Workout = openerQ2Template.map {
                    RoadWorkoutBuilder.build(
                        from: $0, paceProfile: paceProfile,
                        experience: athlete.experienceLevel, athleteAge: athlete.age
                    )
                }
                if let w = openerQ1Workout { allWorkouts.append(w) }
                if let w = openerQ2Workout { allWorkouts.append(w) }

                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                    // RR-4 defense-in-depth: never allow fabricated D+ on road plans
                    // regardless of what any template says.
                    session.plannedElevationGainM = 0

                    if session.type == .intervals, let w = openerQ1Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = openerQ1Template?.category.displayName
                        alignSessionWithWorkout(&session, workout: w)
                    } else if session.type == .tempo, let w = openerQ2Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = openerQ2Template?.category.displayName
                        alignSessionWithWorkout(&session, workout: w)
                    }
                    return session
                }
            } else {
                // Road-specific session selection
                let roadAthleteContext = RoadSessionSelector.AthleteContext(
                    philosophy: athlete.trainingPhilosophy,
                    hasRecentInjury: athlete.hasRecentInjury,
                    painFrequency: athlete.painFrequency,
                    age: athlete.age,
                    weightGoal: athlete.weightGoal,
                    raceName: targetRace.name,
                    isFirstTimerAtDistance: isFirstTimer
                )
                // Final taper week = the very last week of the plan. The
                // selector swaps the day-5 long run slot for a pre-race
                // shakeout (20 min easy + 4 strides at race pace).
                let isFinalTaperWeek = skeleton.phase == .taper
                    && phaseCounters[index] == taperProfile.totalTaperWeeks - 1
                let templates = RoadSessionSelector.sessions(
                    phase: skeleton.phase,
                    volume: volume,
                    discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    isRecoveryWeek: skeleton.isRecoveryWeek,
                    paceProfile: paceProfile,
                    athleteContext: roadAthleteContext,
                    isFinalTaperWeek: isFinalTaperWeek
                )

                // Build IntervalWorkout objects for quality sessions
                // mirror the selector's first-timer template cap so the
                // workout structure matches what the session description
                // already says.
                // RR-33: compose quality sessions parametrically (athlete
                // profile + per-category block progression + shape rotation)
                // rather than picking from the fixed template menu. This is
                // what stops two different athletes getting identical sessions
                // and stops the same work part recurring week to week.
                let q1Cat = RoadIntervalLibrary.slotCategory(
                    phase: skeleton.phase, discipline: discipline, slotIndex: 0,
                    weekInPhase: phaseCounters[index])
                let q2Cat = RoadIntervalLibrary.slotCategory(
                    phase: skeleton.phase, discipline: discipline, slotIndex: 1,
                    weekInPhase: phaseCounters[index], exclude: q1Cat)
                let q1Composed = Self.composeQuality(
                    category: q1Cat, slotIndex: 0, skeleton: skeleton,
                    discipline: discipline, athlete: athlete,
                    weekVolumeKm: volume.targetVolumeKm, paceProfile: paceProfile,
                    isFirstTimer: isFirstTimer, varietySeed: qualityVarietySeed,
                    raceDistanceKm: targetRace.distanceKm,
                    ordinals: &qualityOrdinal, used: &usedQualitySignatures)
                let q2Composed = Self.composeQuality(
                    category: q2Cat, slotIndex: 1, skeleton: skeleton,
                    discipline: discipline, athlete: athlete,
                    weekVolumeKm: volume.targetVolumeKm, paceProfile: paceProfile,
                    isFirstTimer: isFirstTimer,
                    // De-conflict the week's two quality shapes: Q2 avoids
                    // Q1's shape so a week never runs e.g. two pyramids.
                    avoidShape: q1Composed.shape, varietySeed: qualityVarietySeed,
                    raceDistanceKm: targetRace.distanceKm,
                    ordinals: &qualityOrdinal, used: &usedQualitySignatures)
                let q1Template: RoadIntervalLibrary.Template? = q1Composed.template
                let q2Template: RoadIntervalLibrary.Template? = q2Composed.template
                let q1Workout: IntervalWorkout? = q1Composed.workout
                let q2Workout: IntervalWorkout? = q2Composed.workout

                if let w = q1Workout { allWorkouts.append(w) }
                if let w = q2Workout { allWorkouts.append(w) }

                // RR-2: Build a structured long-run workout for Canova-style
                // MP-block / progressive / race-simulation variants so the
                // athlete gets real phase guidance in ActiveRunView instead
                // of just a description string.
                let longRunVariant = RoadLongRunCalculator.variant(
                    phase: skeleton.phase,
                    weekInPhase: phaseCounters[index],
                    raceDistanceKm: targetRace.distanceKm,
                    experience: athlete.experienceLevel,
                    isRecoveryWeek: skeleton.isRecoveryWeek
                )
                let longRunWorkout = RoadLongRunWorkoutBuilder.build(
                    variant: longRunVariant,
                    totalDuration: volume.targetLongRunDurationSeconds,
                    paceProfile: paceProfile,
                    weekInPhase: phaseCounters[index],
                    raceDistanceKm: targetRace.distanceKm
                )
                if let w = longRunWorkout { allWorkouts.append(w) }

                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                    // Attach workout to quality sessions. RR-24: also
                    // surface the interval category (Speed / VO2max /
                    // Threshold / Race pace / ...) onto the session so
                    // the row/detail can label it at a glance instead of
                    // the generic "Intervals" / "Tempo".
                    //
                    // After attaching the workout, align the session's
                    // displayed duration + distance with the workout's
                    // actual content so the card matches the detail.
                    // Without this alignment, the weekly card showed
                    // e.g. "Intervals 16min / 3.0km" while the detail
                    // unpacked to a 5×1km session totalling 42 min /
                    // 13 km, two truths visible to the user.
                    // RR-34: the COMPOSED workout is the single source of
                    // truth for the quality session. We match the slot by the
                    // template's original type (.intervals = Q1, .tempo = Q2),
                    // then (a) write the composed workout's structural name as
                    // the card description so card and detail agree and the
                    // text varies week to week, and (b) re-type the session
                    // from the composed content so a rep workout reads
                    // "Intervals" and a sustained block reads "Tempo",
                    // regardless of which slot it landed in.
                    if tpl.type == .intervals, let w = q1Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = q1Template?.category.displayName
                        session.description = w.name
                        session.type = q1Composed.isTempo ? .tempo : .intervals
                        alignSessionWithWorkout(&session, workout: w)
                    } else if tpl.type == .tempo, let w = q2Workout {
                        session.intervalWorkoutId = w.id
                        session.intervalFocus = q2Template?.category.displayName
                        session.description = w.name
                        session.type = q2Composed.isTempo ? .tempo : .intervals
                        alignSessionWithWorkout(&session, workout: w)
                    } else if session.type == .longRun, let w = longRunWorkout {
                        session.intervalWorkoutId = w.id
                        alignSessionWithWorkout(&session, workout: w)
                        // Long runs with structured work become moderate/hard
                        // sessions, not easy. Mark accordingly so the UI surfaces
                        // them correctly (intensity badges, weekly load calc).
                        switch longRunVariant {
                        case .marathonPaceBlocks, .raceSimulation:
                            session.intensity = .hard
                        case .progressive, .fastFinish, .twoPart, .marathonPaceIntro:
                            session.intensity = .moderate
                        case .easy:
                            break // keep .easy
                        }
                        // Surface the variant as a pill on the session row so
                        // four 2h50 long runs in a row don't read as identical
                        // the work inside changes week to week (MP Blocks, Race
                        // Sim, Fast Finish, Two-Part) even when duration plateaus.
                        session.intervalFocus = longRunVariant.displayLabel
                    }
                    // Pick the matching quality template so coach advice
                    // can prescribe the right pace (cruise vs sustained
                    // for threshold sessions; MP for raceSpecific late-
                    // build, etc.) instead of falling back to the
                    // phase-default which can desync from the workout.
                    // Keyed off the original slot type (tpl.type), not the
                    // re-typed session.type: after RR-34 both quality slots
                    // can resolve to .intervals, so session.type no longer
                    // uniquely identifies which composed template to use.
                    let qualityTemplate: RoadIntervalLibrary.Template?
                    switch tpl.type {
                    case .intervals: qualityTemplate = q1Template
                    case .tempo:     qualityTemplate = q2Template
                    default:         qualityTemplate = nil
                    }
                    // Road-specific coach advice
                    session.coachAdvice = RoadCoachAdviceGenerator.advice(
                        type: session.type, intensity: session.intensity,
                        phase: skeleton.phase, discipline: discipline,
                        isRecoveryWeek: skeleton.isRecoveryWeek,
                        paceProfile: paceProfile,
                        raceName: targetRace.name,
                        experience: athlete.experienceLevel,
                        isFirstTimer: isFirstTimer,
                        isShortPrep: isShortPrep,
                        hotRaceForecast: hotRaceForecast,
                        refinementSummary: refinementSummary,
                        restingHR: athlete.restingHeartRate,
                        maxHR: athlete.maxHeartRate,
                        biologicalSex: athlete.biologicalSex,
                        qualityTemplate: qualityTemplate
                    )
                    return session
                }
            }

            var sessionsAfterSub = sessions

            // RR-18: on the tune-up week, replace the intervals session with
            // a time-trial description. Clear the linked interval workout so
            // ActiveRunView treats it as a free-form GPS run driven by the
            // coach-advice / description text. Skip when recovery or taper
            // week (we shouldn't force a TT on a lighter week).
            if let tuneUpWeekNumber,
               skeleton.weekNumber == tuneUpWeekNumber,
               !skeleton.isRecoveryWeek,
               skeleton.phase != .taper,
               override == nil,
               let ttIdx = sessionsAfterSub.firstIndex(where: { $0.type == .intervals }) {
                let ttDesc = tuneUpTimeTrialDescription(discipline: discipline)
                sessionsAfterSub[ttIdx].description = ttDesc
                sessionsAfterSub[ttIdx].intensity = .maxEffort
                sessionsAfterSub[ttIdx].coachAdvice = tuneUpTimeTrialCoachAdvice(discipline: discipline)
                // Attach a structured warm-up → TT effort → cool-down workout so
                // the athlete sees phase cards, not just the description text.
                if let ttWorkout = RoadLongRunWorkoutBuilder.buildTimeTrial(discipline: discipline, paceProfile: paceProfile) {
                    allWorkouts.append(ttWorkout)
                    sessionsAfterSub[ttIdx].intervalWorkoutId = ttWorkout.id
                    alignSessionWithWorkout(&sessionsAfterSub[ttIdx], workout: ttWorkout)
                } else {
                    sessionsAfterSub[ttIdx].intervalWorkoutId = nil
                }
            }

            // #28: fitness check-in week, replace the week's intervals
            // session with a 2K TT. Same treatment pattern as RR-18
            // but shorter and more frequent, so paces don't drift
            // stale through a long base/build block.
            if fitnessCheckInWeeks.contains(skeleton.weekNumber),
               override == nil,
               let ttIdx = sessionsAfterSub.firstIndex(where: { $0.type == .intervals }) {
                sessionsAfterSub[ttIdx].description = PlanFitnessCheckIn.description
                sessionsAfterSub[ttIdx].intensity = .maxEffort
                sessionsAfterSub[ttIdx].intervalWorkoutId = nil
                sessionsAfterSub[ttIdx].coachAdvice = PlanFitnessCheckIn.coachAdvice
                sessionsAfterSub[ttIdx].intervalFocus = PlanFitnessCheckIn.intervalFocusLabel()
                sessionsAfterSub[ttIdx].isKeySession = true
            }

            // Mid-prep fitness test (opt-in), replace the intervals
            // session with the variant-specific test. Scheduler already
            // ensures we don't collide with a B-race / tune-up / 2K
            // check-in; defensive `override == nil` guards intermediate
            // race weeks.
            if let schedule = fitnessTestSchedule,
               schedule.weekNumber == skeleton.weekNumber,
               override == nil {
                substituteFitnessTest(
                    sessions: &sessionsAfterSub,
                    variant: schedule.variant,
                    allWorkouts: &allWorkouts
                )
            }

            // RR-5: Add S&C sessions for athletes who opted in. Uses the same
            // StrengthSessionGenerator the trail pipeline uses; road-specific
            // emphasis is inherent to the generator's exercise selection.
            var finalSessions = sessionsAfterSub
            if wantsStrength {
                let strengthConfig = StrengthSessionGenerator.Config(
                    experience: athlete.experienceLevel,
                    phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                    location: athlete.strengthTrainingLocation,
                    painFrequency: athlete.painFrequency,
                    injuryCount: athlete.injuryCountLastYear,
                    hasRecentInjury: athlete.hasRecentInjury,
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    weekNumberInPhase: phaseCounters[index],
                    isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                    raceEffectiveKm: raceEffectiveKm,
                    raceType: targetRace.raceType
                )
                // Convert existing TrainingSessions to SessionTemplates for the helper.
                // We only need type + dayOffset for availability computation.
                let runningTemplates: [SessionTemplateGenerator.SessionTemplate] = sessions.map { s in
                    let dayOffset = Calendar.current.dateComponents([.day], from: skeleton.startDate, to: s.date).day ?? 0
                    return SessionTemplateGenerator.SessionTemplate(
                        dayOffset: dayOffset,
                        type: s.type,
                        intensity: s.intensity,
                        durationSeconds: s.plannedDuration,
                        elevationFraction: 0,
                        description: s.description
                    )
                }
                let strength = SessionTemplateGenerator.generateStrengthForWeek(
                    config: strengthConfig,
                    weekStartDate: skeleton.startDate,
                    existingRunningSessions: runningTemplates
                )
                finalSessions.append(contentsOf: strength.sessions)
                finalSessions.sort { $0.date < $1.date }
                allStrengthWorkouts.append(contentsOf: strength.workouts)
            }

            // Round endurance sessions (Long Run, Base Endurance) to
            // the nearest 5 minutes so the road schedule reads cleanly.
            // Mirrors the trail pipeline; quality sessions keep their
            // minute precision because their structure is minute-anchored.
            EnduranceDurationRounder.roundInPlace(&finalSessions)

            let weekDuration = finalSessions
                .filter { $0.type != .rest && $0.type != .strengthConditioning }
                .reduce(0) { $0 + $1.plannedDuration }

            // A-race week beats override label (defensive). Recompute
            // weekly volume from sessions whenever we used pre-built
            // templates (race week or post-race recovery), so the
            // chart reflects the actual prescription.
            let weekPhase: TrainingPhase
            if isARaceWeek {
                weekPhase = .race
            } else if override?.behavior.isRaceWeek == true {
                weekPhase = .race
            } else {
                weekPhase = skeleton.phase
            }

            let usedPrebuilt = isARaceWeek || postRaceRecoveryWeekN != nil
            let weekVolumeKm: Double
            if usedPrebuilt {
                weekVolumeKm = finalSessions
                    .filter { $0.type != .rest && $0.type != .strengthConditioning }
                    .reduce(0) { $0 + $1.plannedDistanceKm }
            } else {
                weekVolumeKm = volume.targetVolumeKm
            }

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: weekPhase,
                sessions: finalSessions,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                targetVolumeKm: weekVolumeKm,
                targetElevationGainM: 0,
                targetDurationSeconds: weekDuration,
                phaseFocus: skeleton.phaseFocus
            )
        }

        let snapshots = intermediateRaces.map { race in
            RaceSnapshot(id: race.id, date: race.date, priority: race.priority)
        }

        var plan = TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            createdAt: .now,
            weeks: Self.applyPreRaceSpilloverTaper(weeks, raceDate: raceDate),
            intermediateRaceIds: intermediateRaces.map(\.id),
            intermediateRaceSnapshots: snapshots
        )
        plan.workouts = allWorkouts
        plan.strengthWorkouts = allStrengthWorkouts
        return plan
    }

    /// Race-day coach advice for ROAD A-races. Distance-class specific
    /// pacing, glycogen, hot-weather, and first-timer cues. Returned as
    /// the session's `coachAdvice` so the athlete sees execution
    /// guidance on race day.
    private func roadRaceDayCoachAdvice(
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?,
        isFirstTimer: Bool,
        hotRaceForecast: Bool
    ) -> String {
        var pieces: [String] = []
        switch discipline {
        case .road5K:
            pieces.append(String(localized: "tpg.raceday.5k", defaultValue: "5K race day. Plan: it's short and honest, settle into goal pace within the first 400m, no easing in. It bites around 3K, hold form and cadence there. The last kilometre is where you empty the tank."))
        case .road10K:
            pieces.append(String(localized: "tpg.raceday.10k", defaultValue: "10K race day. Plan: settle into goal pace by 1K, first kilometre will feel deceptively easy. Hold rhythm through 5K. From 7K onwards, every kilometre buys the next. Strong final 1K is where the time gets earned."))
        case .roadHalf:
            pieces.append(String(localized: "tpg.raceday.half", defaultValue: "Half marathon race day. Plan: first 5K is for patience, sit on (not under) goal pace. 5-15K hold the rhythm. 15K-end is where you race, pick off targets one at a time, lift cadence on the closing kilometres."))
        case .roadMarathon:
            pieces.append(String(localized: "tpg.raceday.marathon", defaultValue: "Marathon race day. Plan: first 10K is for restraint, even 5 sec/km too quick will cost you 5+ minutes by 35K. Lock into goal pace, fuel from kilometre 5 every 25-30 min, drink at every aid station. The race begins at 30K."))
        }
        if isFirstTimer {
            pieces.append(String(localized: "tpg.raceday.firstTimer", defaultValue: "First time at this distance: finishing strong matters more than the clock. Negative split if at all possible."))
        }
        if hotRaceForecast {
            pieces.append(String(localized: "tpg.raceday.hot", defaultValue: "Hot conditions forecast: drink earlier and more, take electrolytes, slow goal pace 5-10 sec/km from the gun, heat compounds."))
        }
        pieces.append(String(localized: "tpg.raceday.trust", defaultValue: "Trust your training. Execute your plan."))
        return pieces.joined(separator: " ")
    }

    /// Creates a TrainingSession from a SessionTemplate (used by road plan).
    private func makeSession(
        template: SessionTemplateGenerator.SessionTemplate,
        skeleton: WeekSkeletonBuilder.WeekSkeleton,
        dayIndex: Int,
        volume: VolumeCalculator.WeekVolume
    ) -> TrainingSession {
        let sessionDate = Calendar.current.date(
            byAdding: .day, value: template.dayOffset, to: skeleton.startDate
        ) ?? skeleton.startDate.addingTimeInterval(TimeInterval(template.dayOffset * 86400))

        let avgPace: Double = 330 // ~5:30/km default
        // Race sessions carry the real race distance (10K, half, marathon)
        // through `distanceKmOverride`; without it, the duration-based
        // estimate kicks in (a 36-min 10K race ÷ 5:30/km = 6.5 km, which
        // is the bug B1 fixes by preferring the override when set).
        let derivedDistanceKm = template.durationSeconds > 0 ? template.durationSeconds / avgPace : 0
        let distanceKm = template.distanceKmOverride ?? derivedDistanceKm
        let elevationM = distanceKm * template.elevationFraction * 50 // Minimal for road

        return TrainingSession(
            id: UUID(),
            date: sessionDate,
            type: template.type,
            plannedDistanceKm: round(distanceKm * 10) / 10,
            plannedElevationGainM: round(elevationM),
            plannedDuration: template.durationSeconds,
            intensity: template.intensity,
            description: template.description,
            isCompleted: false,
            isSkipped: false,
            isKeySession: template.type == .longRun || template.type == .intervals || template.type == .tempo
        )
    }

    private func computeWeekNumbersInPhase(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton]
    ) -> [Int] {
        var counters: [TrainingPhase: Int] = [:]
        return skeletons.map { skeleton in
            let phase = skeleton.phase
            let current = counters[phase, default: 0]
            counters[phase] = current + 1
            return current
        }
    }

    // MARK: - RR-18: Tune-up Time Trial

    /// Returns the weekNumber where a tune-up TT should be auto-inserted, or
    /// nil if we shouldn't insert one (10K prep, or an existing B-race covers
    /// the window). The target week is shortly before the taper starts:
    /// marathon -2 weeks before taper, HM -1 week before.
    private func computeTuneUpWeekNumber(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        taperProfile: TaperProfile,
        discipline: RoadRaceDiscipline,
        existingOverrides: [IntermediateRaceHandler.RaceWeekOverride]
    ) -> Int? {
        let offsetBeforeTaper: Int
        switch discipline {
        case .roadMarathon: offsetBeforeTaper = 2
        case .roadHalf:     offsetBeforeTaper = 1
        case .road5K, .road10K: return nil // Too short to warrant an auto TT
        }

        let totalWeeks = skeletons.count
        let taperStart = totalWeeks - taperProfile.totalTaperWeeks
        let targetIndex = taperStart - 1 - offsetBeforeTaper
        guard targetIndex >= 0, targetIndex < skeletons.count else { return nil }

        let target = skeletons[targetIndex]

        // Don't force a TT on a recovery week or during taper.
        guard !target.isRecoveryWeek, target.phase != .taper else { return nil }

        // Skip if an existing B-race override lands within ±1 week of the target.
        let targetWeekNumber = target.weekNumber
        let conflict = existingOverrides.contains { override in
            override.behavior.isRaceWeek && abs(override.weekNumber - targetWeekNumber) <= 1
        }
        return conflict ? nil : targetWeekNumber
    }

    /// RR-20: first-timer check, true when the athlete has no recorded PB
    /// at the discipline's distance. A PB with timeSeconds == 0 is treated
    /// as no PB (placeholder entries from onboarding).
    private func isFirstTimerAtDistance(
        personalBests: [PersonalBest],
        discipline: RoadRaceDiscipline
    ) -> Bool {
        let targetDistance: PersonalBestDistance
        switch discipline {
        case .road5K:       targetDistance = .fiveK
        case .road10K:      targetDistance = .tenK
        case .roadHalf:     targetDistance = .halfMarathon
        case .roadMarathon: targetDistance = .marathon
        }
        return !personalBests.contains { $0.distance == targetDistance && $0.timeSeconds > 0 }
    }

    private func tuneUpTimeTrialDescription(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return String(localized: "tpg.tt.desc.marathon", defaultValue: "Tune-up 10K Time Trial, 20 min easy warm-up + 4-6 × 20s strides, then 10K all-out sustained effort (HMP-to-10K pace), then 15 min easy cool-down. Your biggest fitness check of the block, execute like a real race.")
        case .roadHalf:
            return String(localized: "tpg.tt.desc.half", defaultValue: "Tune-up 5K Time Trial, 15 min easy warm-up + 4-6 × 20s strides, then 5K all-out sustained effort, then 10 min easy cool-down. Ideally on a track or flat route.")
        case .road5K:
            return String(localized: "tpg.tt.desc.5k", defaultValue: "Tune-up 3K Time Trial, 15 min easy warm-up + 4-6 × 20s strides, then 3K all-out at goal-pace-or-faster, then 10 min easy cool-down. Track or flat route ideal.")
        case .road10K:
            return String(localized: "tpg.tt.desc.10k", defaultValue: "Tune-up time trial.")
        }
    }

    private func tuneUpTimeTrialCoachAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return String(localized: "tpg.tt.coach.marathon", defaultValue: "This is your race-pace calibration session. If you nail HMP effort comfortably, your target is achievable. If you struggle to hold pace past 7K, scale marathon target back by 1-2%.")
        case .roadHalf:
            return String(localized: "tpg.tt.coach.half", defaultValue: "Your 5K time × 2.11 gives a realistic half-marathon target. Use this to validate your goal time.")
        case .road5K, .road10K:
            return ""
        }
    }

    /// Replaces the session's plannedDuration + plannedDistanceKm with
    /// values derived from the attached workout's actual structure.
    /// Used by the road pipeline so the weekly card reads the same
    /// totals the athlete sees when they tap into the workout detail
    ///, instead of the abstract budget that didn't account for
    /// warmup + cooldown around quality sessions.
    /// RR-33: composes one quality session via `IntervalSessionComposer`,
    /// advancing the per-category progression ordinal and guaranteeing the
    /// work part hasn't been used elsewhere in the plan. Recovery weeks
    /// compose a light primer and do NOT advance the ordinal (so the build
    /// resumes after the deload) or reserve a signature (primers may repeat).
    /// Deterministic, launch-stable hash of UUIDs (FNV-1a over their bytes).
    /// Swift's `hashValue` is per-process randomized, so it can't seed plan
    /// variety, regenerating the same prep must reproduce the same plan.
    private static func stableSeed(_ ids: UUID...) -> Int {
        var h: UInt64 = 1469598103934665603 // FNV-1a offset basis
        for id in ids {
            let b = id.uuid
            let bytes = [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7,
                         b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15]
            for byte in bytes {
                h = (h ^ UInt64(byte)) &* 1099511628211 // FNV-1a prime
            }
        }
        return Int(h & 0x7FFF_FFFF)
    }

    private static func composeQuality(
        category: RoadIntervalLibrary.Category,
        slotIndex: Int,
        skeleton: WeekSkeletonBuilder.WeekSkeleton,
        discipline: RoadRaceDiscipline,
        athlete: Athlete,
        weekVolumeKm: Double,
        paceProfile: RoadPaceProfile?,
        isFirstTimer: Bool,
        avoidShape: IntervalSessionComposer.Shape? = nil,
        varietySeed: Int,
        raceDistanceKm: Double,
        ordinals: inout [RoadIntervalLibrary.Category: Int],
        used: inout Set<String>
    ) -> IntervalSessionComposer.Composed {
        func make(_ ordinal: Int) -> IntervalSessionComposer.Composed {
            IntervalSessionComposer.compose(IntervalSessionComposer.Context(
                category: category, phase: skeleton.phase, discipline: discipline,
                experience: athlete.experienceLevel, weeklyVolumeKm: weekVolumeKm,
                paceProfile: paceProfile, raceDistanceKm: raceDistanceKm,
                ordinal: ordinal, slotIndex: slotIndex,
                isRecoveryWeek: skeleton.isRecoveryWeek, isFirstTimer: isFirstTimer,
                athleteAge: athlete.age, avoidShape: avoidShape, varietySeed: varietySeed
            ))
        }

        // Recovery-week primers repeat by design; don't track them.
        guard !skeleton.isRecoveryWeek else { return make(ordinals[category] ?? 0) }

        var ordinal = ordinals[category] ?? 0
        var composed = make(ordinal)
        var tries = 0
        while used.contains(composed.signature) && tries < 4 {
            ordinal += 1
            composed = make(ordinal)
            tries += 1
        }
        used.insert(composed.signature)
        ordinals[category] = ordinal + 1
        return composed
    }

    private func alignSessionWithWorkout(_ session: inout TrainingSession, workout: IntervalWorkout) {
        guard workout.estimatedDurationSeconds > 0 else { return }
        let avgPaceSecPerKm: Double = 330  // ~5:30/km baseline (matches makeSession)
        session.plannedDuration = workout.estimatedDurationSeconds
        session.plannedDistanceKm = round(workout.estimatedDurationSeconds / avgPaceSecPerKm * 10) / 10
    }

    /// Counts ultra finishes (≥30 km trail PBs) used to set the
    /// ultra-experience multiplier on `PersonalizationProfile`. PBs
    /// with `timeSeconds == 0` are treated as placeholders and excluded.
    private func countUltraFinishes(athlete: Athlete) -> Int {
        athlete.trailPersonalBests.filter {
            $0.distanceKm >= 30 && $0.timeSeconds > 0
        }.count
    }

    /// Pulls the athlete's last 90 days of completed runs for
    /// PersonalizationProfile's recent-peak computation. Returns
    /// `[]` when no run repository is wired (existing tests, DI
    /// containers that don't pass one) so the personalization layer
    /// falls back to the snapshot baseline. Errors are swallowed
    /// a failed history fetch must never block plan generation.
    private func fetchRecentRuns(for athlete: Athlete) async -> [CompletedRun] {
        guard let runRepository else { return [] }
        let now = Date.now
        guard let windowStart = Calendar.current.date(
            byAdding: .day, value: -90, to: now
        ) else { return [] }
        do {
            return try await runRepository.getRuns(from: windowStart, to: now)
        } catch {
            return []
        }
    }

    /// Substitutes the first quality slot (intervals → tempo → vertical
    /// gain) in the week's sessions with a fitness test session.
    /// Idempotent: if no quality slot exists, no-op (defensive, every
    /// non-recovery base/build week has at least one quality slot in
    /// our pipelines). Encodes the variant into `intervalFocus` so the
    /// session-validation flow can recover it without separate state.
    private func substituteFitnessTest(
        sessions: inout [TrainingSession],
        variant: FitnessTestVariant,
        allWorkouts: inout [IntervalWorkout]
    ) {
        let qualityPriority: [SessionType] = [.intervals, .tempo, .verticalGain]
        for type in qualityPriority {
            if let idx = sessions.firstIndex(where: { $0.type == type }) {
                sessions[idx].description = variant.description
                sessions[idx].coachAdvice = variant.coachAdvice
                sessions[idx].intensity = .maxEffort
                sessions[idx].intervalFocus = variant.intervalFocusEncoded
                sessions[idx].isKeySession = true
                // Attach a structured warm-up → effort → cool-down workout so
                // the test shows phase cards, not just description text.
                let workout = variant.workout
                allWorkouts.append(workout)
                sessions[idx].intervalWorkoutId = workout.id
                alignSessionWithWorkout(&sessions[idx], workout: workout)
                return
            }
        }
    }

    /// Day-aware pre-race taper guard. The taper is allocated by calendar WEEK,
    /// so when the A-race falls EARLY in its week (e.g. a Monday race), the real
    /// final days before the race spill into the PRIOR calendar week — which
    /// stays at full peak volume, leaving things like a 2-hour long run two days
    /// out. This downgrades any long run / quality session landing within 4 days
    /// before the race in a week earlier than the race week into a short easy
    /// shakeout. Races on Thu-Sun are unaffected: their final days already fit
    /// inside the race week's own taper.
    static func applyPreRaceSpilloverTaper(_ weeks: [TrainingWeek], raceDate: Date) -> [TrainingWeek] {
        let cal = Calendar.current
        let raceDay = cal.startOfDay(for: raceDate)
        let raceWeekStart = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: raceDay)
        ) ?? raceDay

        return weeks.map { week in
            var w = week
            w.sessions = week.sessions.map { session in
                let sDay = cal.startOfDay(for: session.date)
                // Never touch the race week itself (its taper is already right).
                guard sDay < raceWeekStart else { return session }
                let days = cal.dateComponents([.day], from: sDay, to: raceDay).day ?? 99
                guard days >= 1, days <= 4 else { return session }
                return downgradeToPreRaceShakeout(session, daysUntilRace: days)
            }
            return w
        }
    }

    /// Turns a too-close-to-race session into a short easy shakeout (or trims an
    /// already-easy run). Closer to the race ⇒ shorter cap.
    static func downgradeToPreRaceShakeout(_ session: TrainingSession, daysUntilRace: Int) -> TrainingSession {
        let cap: TimeInterval = daysUntilRace <= 1 ? 25 * 60 : (daysUntilRace == 2 ? 30 * 60 : 40 * 60)
        let heavy: Set<SessionType> = [.longRun, .intervals, .tempo, .verticalGain, .backToBack]

        if heavy.contains(session.type) {
            var out = session
            out.type = .recovery
            out.intensity = .easy
            out.plannedDuration = min(session.plannedDuration, cap)
            out.plannedElevationGainM = 0
            out.plannedDistanceKm = round(out.plannedDuration / 330 * 10) / 10
            out.intervalWorkoutId = nil
            out.intervalFocus = nil
            out.isKeySession = false
            out.coachAdvice = nil
            out.description = String(localized: "tpg.preRace.shakeout", defaultValue: "Easy pre-race shakeout, keep it short and relaxed.")
            return out
        }
        if session.type == .recovery, session.plannedDuration > cap {
            var out = session
            out.plannedDuration = cap
            out.plannedDistanceKm = round(cap / 330 * 10) / 10
            return out
        }
        return session
    }
}
