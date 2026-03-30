import Foundation

struct PlanPreferenceReframer: ReframePlanForPreferencesUseCase {

    func execute(
        currentPlan: TrainingPlan,
        updatedAthlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan? {
        let today = Date.now.startOfDay
        let raceDate = targetRace.date.startOfDay

        // 1. Split into past and future weeks
        let splitIndex = currentPlan.weeks.firstIndex { $0.startDate.startOfDay > today }
        guard let splitIndex, splitIndex < currentPlan.weeks.count else {
            return nil // No future weeks to reframe
        }

        let pastWeeks = Array(currentPlan.weeks[..<splitIndex])
        let futureWeekCount = currentPlan.weeks.count - splitIndex

        guard futureWeekCount >= 1 else { return nil }

        // 2. Get anchor volume from last non-recovery past week
        let anchorDuration = pastWeeks
            .last(where: { !$0.isRecoveryWeek })?.targetDurationSeconds

        // 3. Regenerate future weeks using the standard pipeline
        let taperProfile = TaperProfile.forRace(effectiveKm: targetRace.effectiveDistanceKm)
        let phases = PhaseDistributor.distribute(
            totalWeeks: futureWeekCount,
            experience: updatedAthlete.experienceLevel,
            taperProfile: taperProfile
        )

        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases
        )

        let raceDuration = targetRace.estimatedDuration(experience: updatedAthlete.experienceLevel)
        let raceEffectiveKm = targetRace.effectiveDistanceKm

        var volumes = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: updatedAthlete.weeklyVolumeKm,
            raceDistanceKm: targetRace.distanceKm,
            raceElevationGainM: targetRace.elevationGainM,
            experience: updatedAthlete.experienceLevel,
            philosophy: updatedAthlete.trainingPhilosophy,
            raceGoal: targetRace.goalType,
            raceDurationSeconds: raceDuration,
            raceEffectiveKm: raceEffectiveKm,
            preferredRunsPerWeek: updatedAthlete.preferredRunsPerWeek,
            taperProfile: taperProfile
        )

        // 4. Bridge volume: clamp first future week to ±10% of anchor
        if let anchor = anchorDuration, anchor > 0, !volumes.isEmpty {
            volumes[0] = bridgeVolume(original: volumes[0], anchorDuration: anchor)
        }

        // 5. Generate sessions per future week
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: intermediateRaces
        )

        let phaseCounters = computeWeekNumbersInPhase(skeletons: skeletons)
        let lastPastWeekNumber = pastWeeks.last?.weekNumber ?? 0

        var allWorkouts: [IntervalWorkout] = currentPlan.workouts
        var futureWeeks: [TrainingWeek] = []

        for (index, pair) in zip(skeletons, volumes).enumerated() {
            let (skeleton, volume) = pair
            let override = overrides.first { $0.weekNumber == skeleton.weekNumber }

            let result = SessionTemplateGenerator.sessions(
                for: skeleton,
                volume: volume,
                experience: updatedAthlete.experienceLevel,
                raceEffectiveKm: raceEffectiveKm,
                raceElevationGainM: targetRace.elevationGainM,
                totalWeeks: futureWeekCount,
                philosophy: updatedAthlete.trainingPhilosophy,
                weekNumberInPhase: phaseCounters[index],
                raceOverride: override,
                preferredRunsPerWeek: updatedAthlete.preferredRunsPerWeek,
                verticalGainEnvironment: updatedAthlete.verticalGainEnvironment,
                expectedRaceDuration: raceDuration
            )

            allWorkouts.append(contentsOf: result.workouts)

            let week = TrainingWeek(
                id: UUID(),
                weekNumber: lastPastWeekNumber + skeleton.weekNumber,
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
            futureWeeks.append(week)
        }

        // 6. Merge past + future into updated plan
        var reframed = currentPlan
        reframed.weeks = pastWeeks + futureWeeks
        reframed.workouts = allWorkouts

        return reframed
    }

    // MARK: - Volume Bridging

    private func bridgeVolume(
        original: VolumeCalculator.WeekVolume,
        anchorDuration: TimeInterval
    ) -> VolumeCalculator.WeekVolume {
        let maxChange = AppConfiguration.Training.maxWeeklyVolumeIncreasePercent / 100.0
        let newDuration = original.targetDurationSeconds

        guard anchorDuration > 0 else { return original }
        let ratio = (newDuration - anchorDuration) / anchorDuration
        guard abs(ratio) > maxChange else { return original }

        let clampedDuration = ratio > 0
            ? anchorDuration * (1 + maxChange)
            : anchorDuration * (1 - maxChange)

        let scale = clampedDuration / newDuration

        return VolumeCalculator.WeekVolume(
            weekNumber: original.weekNumber,
            targetVolumeKm: (original.targetVolumeKm * scale * 10).rounded() / 10,
            targetElevationGainM: ((original.targetElevationGainM * scale) / 5.0).rounded() * 5.0,
            targetDurationSeconds: clampedDuration,
            targetLongRunDurationSeconds: original.targetLongRunDurationSeconds * scale,
            isB2BWeek: original.isB2BWeek,
            b2bDay1Seconds: original.b2bDay1Seconds * scale,
            b2bDay2Seconds: original.b2bDay2Seconds * scale,
            baseSessionDurations: VolumeCalculator.BaseSessionDurations(
                easyRun1Seconds: original.baseSessionDurations.easyRun1Seconds * scale,
                easyRun2Seconds: original.baseSessionDurations.easyRun2Seconds * scale,
                intervalSeconds: original.baseSessionDurations.intervalSeconds * scale,
                vgSeconds: original.baseSessionDurations.vgSeconds * scale
            ),
            weekNumberInTaper: original.weekNumberInTaper,
            taperProfile: original.taperProfile
        )
    }

    // MARK: - Helpers

    private func computeWeekNumbersInPhase(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton]
    ) -> [Int] {
        var counters: [TrainingPhase: Int] = [:]
        return skeletons.map { skeleton in
            let current = counters[skeleton.phase, default: 0]
            counters[skeleton.phase] = current + 1
            return current
        }
    }
}
