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

        // 3. Build week skeletons (reuse existing builder)
        let recoveryCycle = VolumeCapCalculator.recoveryCycle(for: athlete.experienceLevel)
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

        // 6. Compute pace profile for session descriptions
        let goalTime: TimeInterval?
        if case .targetTime(let time) = targetRace.goalType {
            goalTime = time
        } else {
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

        // 8. Generate sessions for each week
        var allWorkouts: [IntervalWorkout] = []

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
                    raceContext: intermediateRaceContext
                )
                sessions = templates.enumerated().map { dayIdx, tpl in
                    makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                }
            } else {
                // Road-specific session selection
                let templates = RoadSessionSelector.sessions(
                    phase: skeleton.phase,
                    volume: volume,
                    discipline: discipline,
                    experience: athlete.experienceLevel,
                    weekInPhase: phaseCounters[index],
                    preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                    isRecoveryWeek: skeleton.isRecoveryWeek,
                    paceProfile: paceProfile
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

                let q1Workout = q1Template.map { RoadWorkoutBuilder.build(from: $0, paceProfile: paceProfile, experience: athlete.experienceLevel) }
                let q2Workout = q2Template.map { RoadWorkoutBuilder.build(from: $0, paceProfile: paceProfile, experience: athlete.experienceLevel) }

                if let w = q1Workout { allWorkouts.append(w) }
                if let w = q2Workout { allWorkouts.append(w) }

                sessions = templates.enumerated().map { dayIdx, tpl in
                    var session = makeSession(template: tpl, skeleton: skeleton, dayIndex: dayIdx, volume: volume)
                    // Attach workout to quality sessions
                    if session.type == .intervals, let w = q1Workout {
                        session.intervalWorkoutId = w.id
                    } else if session.type == .tempo, let w = q2Workout {
                        session.intervalWorkoutId = w.id
                    }
                    // Road-specific coach advice
                    session.coachAdvice = RoadCoachAdviceGenerator.advice(
                        type: session.type, intensity: session.intensity,
                        phase: skeleton.phase, discipline: discipline,
                        isRecoveryWeek: skeleton.isRecoveryWeek,
                        paceProfile: paceProfile
                    )
                    return session
                }
            }

            let weekDuration = sessions
                .filter { $0.type != .rest && $0.type != .strengthConditioning }
                .reduce(0) { $0 + $1.plannedDuration }

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                sessions: sessions,
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
}
