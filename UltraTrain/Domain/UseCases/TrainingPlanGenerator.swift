import Foundation

struct TrainingPlanGenerator: GenerateTrainingPlanUseCase {

    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan {
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

        // 3. Calculate volumes (with dynamic caps and anchoring)
        let raceDuration = targetRace.estimatedDuration(experience: athlete.experienceLevel)
        let raceEffectiveKm = targetRace.effectiveDistanceKm
        let volumes = VolumeCalculator.calculate(
            skeletons: skeletons,
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

        // 4. Compute intermediate race overrides
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces
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
