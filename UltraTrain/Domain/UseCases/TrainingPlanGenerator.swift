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
        let volumes = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: athlete.weeklyVolumeKm,
            raceDistanceKm: targetRace.distanceKm,
            raceElevationGainM: targetRace.elevationGainM,
            experience: athlete.experienceLevel
        )

        // 4. Compute intermediate race overrides
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces
        )

        // 5. Generate sessions for each week
        let weeks: [TrainingWeek] = zip(skeletons, volumes).map { skeleton, volume in
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }

            let sessions = SessionTemplateGenerator.sessions(
                for: skeleton,
                volume: volume,
                experience: athlete.experienceLevel,
                raceOverride: override
            )

            return TrainingWeek(
                id: UUID(),
                weekNumber: skeleton.weekNumber,
                startDate: skeleton.startDate,
                endDate: skeleton.endDate,
                phase: override?.behavior == .raceWeek ? .race : skeleton.phase,
                sessions: sessions,
                isRecoveryWeek: skeleton.isRecoveryWeek || override?.behavior == .postRaceRecovery,
                targetVolumeKm: volume.targetVolumeKm,
                targetElevationGainM: volume.targetElevationGainM
            )
        }

        return TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: intermediateRaces.map(\.id)
        )
    }
}
