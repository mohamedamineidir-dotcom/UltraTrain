import Foundation

/// Applies a refreshed `RoadPaceProfile` to every still-mutable session
/// in a training plan from a given week index forward, refreshing both
/// coach advice prose and the structured interval workout so the pace
/// targets the athlete sees on each session match their current fitness.
///
/// Extracted from `TrainingPlanViewModel+SessionActions` so both the
/// fitness-test recalibration flow (interval-based test result) and the
/// new personal-best recalibration flow (athlete logs a new PR) share
/// the same plumbing.
enum PaceProfileApplier {

    /// Walks `plan.weeks[fromWeekIndex...]` and applies `profile` to
    /// every non-completed, non-skipped intervals / tempo / longRun /
    /// recovery session. Sessions that already carry a fitness-test
    /// focus are left alone (their advice text is owned by the test
    /// flow). Returns the count of sessions actually updated, useful
    /// for surfacing a "12 sessions updated" summary to the athlete.
    @discardableResult
    static func apply(
        to plan: inout TrainingPlan,
        fromWeekIndex: Int,
        profile: RoadPaceProfile,
        targetRace: Race,
        athlete: Athlete
    ) -> Int {
        guard targetRace.raceType == .road else { return 0 }
        guard fromWeekIndex < plan.weeks.count else { return 0 }

        let discipline = RoadRaceDiscipline.from(distanceKm: targetRace.distanceKm)
        let touchedTypes: Set<SessionType> = [.intervals, .tempo, .longRun, .recovery]
        let isFirstTimer = !athlete.personalBests.contains { pb in
            pb.timeSeconds > 0 && {
                switch discipline {
                case .road5K:       return pb.distance == .fiveK
                case .road10K:      return pb.distance == .tenK
                case .roadHalf:     return pb.distance == .halfMarathon
                case .roadMarathon: return pb.distance == .marathon
                }
            }()
        }

        // Track week-in-phase so RoadIntervalLibrary picks the same
        // walk-forward template the original generation pipeline would
        // have at this phase position.
        var weekInPhaseCounter: [TrainingPhase: Int] = [:]
        for w in 0..<fromWeekIndex {
            let phase = plan.weeks[w].phase
            weekInPhaseCounter[phase, default: 0] += 1
        }

        var updatedCount = 0

        for wi in fromWeekIndex..<plan.weeks.count {
            let week = plan.weeks[wi]
            let weekInPhase = weekInPhaseCounter[week.phase, default: 0]
            weekInPhaseCounter[week.phase, default: 0] += 1

            for si in 0..<plan.weeks[wi].sessions.count {
                let session = plan.weeks[wi].sessions[si]
                guard !session.isCompleted, !session.isSkipped else { continue }
                guard touchedTypes.contains(session.type) else { continue }
                if FitnessTestVariant.isFitnessTestFocus(session.intervalFocus) { continue }

                // 1. Refresh coach advice with the new pace profile.
                let newAdvice = RoadCoachAdviceGenerator.advice(
                    type: session.type,
                    intensity: session.intensity,
                    phase: week.phase,
                    discipline: discipline,
                    isRecoveryWeek: week.isRecoveryWeek,
                    paceProfile: profile,
                    raceName: targetRace.name,
                    experience: athlete.experienceLevel,
                    isFirstTimer: isFirstTimer,
                    isShortPrep: false,
                    hotRaceForecast: false,
                    refinementSummary: nil,
                    restingHR: athlete.restingHeartRate,
                    maxHR: athlete.maxHeartRate,
                    biologicalSex: athlete.biologicalSex,
                    qualityTemplate: nil
                )
                if let advice = newAdvice {
                    plan.weeks[wi].sessions[si].coachAdvice = advice
                }

                // 2. Rebuild the structured workout (when one is linked)
                // so workout-detail phases match the new pace anchor.
                guard let workoutId = session.intervalWorkoutId else {
                    updatedCount += 1
                    continue
                }
                guard let newWorkout = rebuildWorkout(
                    for: session,
                    week: week,
                    weekInPhase: weekInPhase,
                    discipline: discipline,
                    raceDistanceKm: targetRace.distanceKm,
                    profile: profile,
                    experience: athlete.experienceLevel,
                    age: athlete.age,
                    isFirstTimer: isFirstTimer
                ) else {
                    updatedCount += 1
                    continue
                }

                // Preserve workout UUID so session.intervalWorkoutId stays valid.
                let stableWorkout = IntervalWorkout(
                    id: workoutId,
                    name: newWorkout.name,
                    descriptionText: newWorkout.descriptionText,
                    phases: newWorkout.phases,
                    category: newWorkout.category,
                    estimatedDurationSeconds: newWorkout.estimatedDurationSeconds,
                    estimatedDistanceKm: newWorkout.estimatedDistanceKm,
                    isUserCreated: newWorkout.isUserCreated
                )
                if let widx = plan.workouts.firstIndex(where: { $0.id == workoutId }) {
                    plan.workouts[widx] = stableWorkout
                }
                if stableWorkout.estimatedDurationSeconds > 0 {
                    plan.weeks[wi].sessions[si].plannedDuration = stableWorkout.estimatedDurationSeconds
                }
                updatedCount += 1
            }
        }

        return updatedCount
    }

    // MARK: - Workout rebuild

    private static func rebuildWorkout(
        for session: TrainingSession,
        week: TrainingWeek,
        weekInPhase: Int,
        discipline: RoadRaceDiscipline,
        raceDistanceKm: Double,
        profile: RoadPaceProfile,
        experience: ExperienceLevel,
        age: Int,
        isFirstTimer: Bool
    ) -> IntervalWorkout? {
        switch session.type {
        case .intervals:
            guard let template = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0, phase: week.phase, discipline: discipline,
                experience: experience, weekInPhase: weekInPhase,
                isFirstTimerAtDistance: isFirstTimer
            ) else { return nil }
            return RoadWorkoutBuilder.build(
                from: template, paceProfile: profile,
                experience: experience, athleteAge: age
            )
        case .tempo:
            let q1 = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0, phase: week.phase, discipline: discipline,
                experience: experience, weekInPhase: weekInPhase,
                isFirstTimerAtDistance: isFirstTimer
            )
            guard let template = RoadIntervalLibrary.selectForSlot(
                slotIndex: 1, phase: week.phase, discipline: discipline,
                experience: experience, weekInPhase: weekInPhase,
                excludeCategory: q1?.category,
                isFirstTimerAtDistance: isFirstTimer
            ) else { return nil }
            return RoadWorkoutBuilder.build(
                from: template, paceProfile: profile,
                experience: experience, athleteAge: age
            )
        case .longRun:
            let variant = RoadLongRunCalculator.variant(
                phase: week.phase,
                weekInPhase: weekInPhase,
                raceDistanceKm: raceDistanceKm,
                experience: experience,
                isRecoveryWeek: week.isRecoveryWeek
            )
            return RoadLongRunWorkoutBuilder.build(
                variant: variant,
                totalDuration: session.plannedDuration,
                paceProfile: profile,
                weekInPhase: weekInPhase,
                raceDistanceKm: raceDistanceKm
            )
        default:
            return nil
        }
    }
}
