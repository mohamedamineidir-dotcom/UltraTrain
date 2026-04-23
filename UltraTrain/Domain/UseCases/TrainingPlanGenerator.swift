import Foundation

struct TrainingPlanGenerator: GenerateTrainingPlanUseCase {

    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan {
        // Road race branch: completely separate pipeline, zero trail logic changes.
        if targetRace.raceType == .road {
            return try generateRoadPlan(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces
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

        // 1. Distribute phases (race-aware taper)
        let taperProfile = TaperProfile.forRace(effectiveKm: targetRace.effectiveDistanceKm)
        let phases = PhaseDistributor.distribute(
            totalWeeks: totalWeeks,
            experience: athlete.experienceLevel,
            taperProfile: taperProfile
        )

        // 2. Build week skeletons (experience-based recovery cycle)
        let recoveryCycle = VolumeCapCalculator.recoveryCycle(for: athlete.experienceLevel)
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases,
            recoveryCycle: recoveryCycle
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
        let volumes = VolumeCalculator.calculate(
            skeletons: volumeSkeletons,
            currentWeeklyVolumeKm: athlete.weeklyVolumeKm,
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
            taperProfile: taperProfile
        )

        // 5. Track week number within each phase
        let phaseCounters = computeWeekNumbersInPhase(skeletons: skeletons)

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
                    raceEffectiveKm: raceEffectiveKm
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

            // Build race context for intermediate race overrides
            let intermediateRaceContext: SessionTemplateGenerator.RaceContext?
            if let raceId = override?.raceId,
               let intRace = intermediateRaces.first(where: { $0.id == raceId }) {
                intermediateRaceContext = .init(
                    name: intRace.name,
                    distanceKm: intRace.distanceKm,
                    elevationGainM: intRace.elevationGainM,
                    estimatedDurationSeconds: intRace.estimatedDuration(experience: athlete.experienceLevel),
                    goalType: intRace.goalType
                )
            } else {
                intermediateRaceContext = nil
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
                intermediateRaceContext: intermediateRaceContext
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

            // For override weeks, recalculate duration from actual sessions
            let weekDuration: TimeInterval
            if override != nil {
                weekDuration = adapted.sessions
                    .filter { $0.type != .rest && $0.type != .strengthConditioning }
                    .reduce(0) { $0 + $1.plannedDuration }
            } else {
                weekDuration = volume.targetDurationSeconds > 0
                    ? volume.targetDurationSeconds
                    : adapted.sessions
                        .filter { $0.type != .rest && $0.type != .strengthConditioning }
                        .reduce(0) { $0 + $1.plannedDuration }
            }

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                sessions: adapted.sessions,
                isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                targetVolumeKm: volume.targetVolumeKm,
                targetElevationGainM: volume.targetElevationGainM,
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
            weeks: weeks,
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
        intermediateRaces: [Race]
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

        // 3. Build week skeletons — road-specific recovery cycle
        let recoveryCycle = VolumeCapCalculator.roadRecoveryCycle(for: athlete.experienceLevel, discipline: discipline)
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases,
            recoveryCycle: recoveryCycle
        )

        // 4. Road-specific volume calculation
        let volumes = RoadVolumeCalculator.calculate(
            skeletons: skeletons,
            athlete: athlete,
            raceDistanceKm: targetRace.distanceKm,
            taperProfile: taperProfile
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
        let paceProfile = RoadPaceCalculator.paceProfile(
            goalTime: goalTime,
            raceDistanceKm: targetRace.distanceKm,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )

        // 7. Phase counters
        let phaseCounters = computeWeekNumbersInPhase(skeletons: skeletons)

        // RR-18: auto-insert a tune-up time-trial in a coach-appropriate
        // week when the athlete has no B-race nearby. Pfitzinger prescribes
        // a tune-up race at week -5 for marathon, week -3 for HM. Our
        // insertion targets the week BEFORE the taper starts (less 1 for
        // HM, less 2 for marathon), skipped entirely for 10K (too short).
        // If a B-race override already falls within ±1 week of the target,
        // we skip auto-insertion — athlete already has a sharpening race.
        let tuneUpWeekNumber = computeTuneUpWeekNumber(
            skeletons: skeletons,
            taperProfile: taperProfile,
            discipline: discipline,
            existingOverrides: overrides
        )

        // 8. Generate sessions for each week
        var allWorkouts: [IntervalWorkout] = []
        var allStrengthWorkouts: [StrengthWorkout] = []

        // RR-5: Road athletes who opted into strength training need S&C
        // sessions on the plan. Previously the road branch never called
        // StrengthSessionGenerator, so opted-in athletes got zero strength
        // work in their plan. Same Config shape as the trail pipeline.
        let wantsStrength = athlete.strengthTrainingPreference == .yes

        let raceEffectiveKm = targetRace.distanceKm + (targetRace.elevationGainM / 100.0)

        let weeks: [TrainingWeek] = zip(skeletons, volumes).enumerated().map { index, pair in
            let (skeleton, volume) = pair
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }

            let sessions: [TrainingSession]
            if let override {
                // Use existing override templates for intermediate race weeks
                let intermediateRaceContext: SessionTemplateGenerator.RaceContext?
                let raceId = override.raceId
                if let intRace = intermediateRaces.first(where: { $0.id == raceId }) {
                    intermediateRaceContext = .init(
                        name: intRace.name, distanceKm: intRace.distanceKm,
                        elevationGainM: intRace.elevationGainM,
                        estimatedDurationSeconds: intRace.estimatedDuration(experience: athlete.experienceLevel),
                        goalType: intRace.goalType
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
                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                    // RR-4 defense-in-depth: never allow fabricated D+ on road plans
                    // regardless of what any template says.
                    session.plannedElevationGainM = 0
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
                    raceName: targetRace.name
                )
                let templates = RoadSessionSelector.sessions(
                    phase: skeleton.phase,
                    volume: volume,
                    discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    isRecoveryWeek: skeleton.isRecoveryWeek,
                    paceProfile: paceProfile,
                    athleteContext: roadAthleteContext
                )

                // Build IntervalWorkout objects for quality sessions
                let q1Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 0, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel, weekInPhase: phaseCounters[index]
                )
                let q2Template = RoadIntervalLibrary.selectForSlot(
                    slotIndex: 1, phase: skeleton.phase, discipline: discipline,
                    experience: athlete.experienceLevel, weekInPhase: phaseCounters[index],
                    excludeCategory: q1Template?.category
                )

                let q1Workout = q1Template.map { RoadWorkoutBuilder.build(from: $0, paceProfile: paceProfile, experience: athlete.experienceLevel, athleteAge: athlete.age) }
                let q2Workout = q2Template.map { RoadWorkoutBuilder.build(from: $0, paceProfile: paceProfile, experience: athlete.experienceLevel, athleteAge: athlete.age) }

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
                    weekInPhase: phaseCounters[index]
                )
                if let w = longRunWorkout { allWorkouts.append(w) }

                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                    // Attach workout to quality sessions
                    if session.type == .intervals, let w = q1Workout {
                        session.intervalWorkoutId = w.id
                    } else if session.type == .tempo, let w = q2Workout {
                        session.intervalWorkoutId = w.id
                    } else if session.type == .longRun, let w = longRunWorkout {
                        session.intervalWorkoutId = w.id
                        // Long runs with structured work become moderate/hard
                        // sessions, not easy. Mark accordingly so the UI surfaces
                        // them correctly (intensity badges, weekly load calc).
                        switch longRunVariant {
                        case .marathonPaceBlocks, .raceSimulation:
                            session.intensity = .hard
                        case .progressive, .fastFinish, .twoPart:
                            session.intensity = .moderate
                        case .easy:
                            break // keep .easy
                        }
                    }
                    // Road-specific coach advice
                    session.coachAdvice = RoadCoachAdviceGenerator.advice(
                        type: session.type, intensity: session.intensity,
                        phase: skeleton.phase, discipline: discipline,
                        isRecoveryWeek: skeleton.isRecoveryWeek,
                        paceProfile: paceProfile,
                        raceName: targetRace.name,
                        experience: athlete.experienceLevel
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
                sessionsAfterSub[ttIdx].intervalWorkoutId = nil
                sessionsAfterSub[ttIdx].coachAdvice = tuneUpTimeTrialCoachAdvice(discipline: discipline)
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
                    raceEffectiveKm: raceEffectiveKm
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

            let weekDuration = finalSessions
                .filter { $0.type != .rest && $0.type != .strengthConditioning }
                .reduce(0) { $0 + $1.plannedDuration }

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                sessions: finalSessions,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                targetVolumeKm: volume.targetVolumeKm,
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
            weeks: weeks,
            intermediateRaceIds: intermediateRaces.map(\.id),
            intermediateRaceSnapshots: snapshots
        )
        plan.workouts = allWorkouts
        plan.strengthWorkouts = allStrengthWorkouts
        return plan
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
        let distanceKm = template.durationSeconds > 0 ? template.durationSeconds / avgPace : 0
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
        case .road10K:      return nil // Too short to warrant an auto TT
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

    private func tuneUpTimeTrialDescription(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return "Tune-up 10K Time Trial — 20 min easy warm-up + 4-6 × 20s strides, then 10K all-out sustained effort (HMP-to-10K pace), then 15 min easy cool-down. Your biggest fitness check of the block — execute like a real race."
        case .roadHalf:
            return "Tune-up 5K Time Trial — 15 min easy warm-up + 4-6 × 20s strides, then 5K all-out sustained effort, then 10 min easy cool-down. Ideally on a track or flat route."
        case .road10K:
            return "Tune-up time trial."
        }
    }

    private func tuneUpTimeTrialCoachAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return "This is your race-pace calibration session. If you nail HMP effort comfortably, your target is achievable. If you struggle to hold pace past 7K, scale marathon target back by 1-2%."
        case .roadHalf:
            return "5K TT result × 2.11 (Riegel) gives your realistic half marathon target. Use this to validate your goal time."
        case .road10K:
            return ""
        }
    }
}
