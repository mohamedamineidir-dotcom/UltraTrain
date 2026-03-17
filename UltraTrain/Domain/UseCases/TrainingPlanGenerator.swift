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

        // 1. Distribute phases
        let phases = PhaseDistributor.distribute(
            totalWeeks: totalWeeks,
            experience: athlete.experienceLevel
        )

        // 2. Build week skeletons
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases
        )

        // 3. Calculate volumes
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
            preferredRunsPerWeek: athlete.preferredRunsPerWeek
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

        let weeks: [TrainingWeek] = zip(skeletons, volumes).enumerated().map { index, pair in
            let (skeleton, volume) = pair
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }

            let result = SessionTemplateGenerator.sessions(
                for: skeleton,
                volume: volume,
                experience: athlete.experienceLevel,
                raceEffectiveKm: raceEffectiveKm,
                weekNumberInPhase: phaseCounters[index],
                raceOverride: override,
                preferredRunsPerWeek: athlete.preferredRunsPerWeek,
                verticalGainEnvironment: athlete.verticalGainEnvironment,

                expectedRaceDuration: raceDuration
            )

            allWorkouts.append(contentsOf: result.workouts)

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: override?.behavior.isRaceWeek == true ? .race : skeleton.phase,
                sessions: result.sessions,
                isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                targetVolumeKm: volume.targetVolumeKm,
                targetElevationGainM: volume.targetElevationGainM,
                targetDurationSeconds: volume.targetDurationSeconds,
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
