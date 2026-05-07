import Foundation

enum TrainingPlanSwiftDataMapper {

    // MARK: - To Domain

    static func toDomain(_ model: TrainingPlanSwiftDataModel) -> TrainingPlan? {
        let weeks = model.weeks
            .sorted { $0.weekNumber < $1.weekNumber }
            .compactMap { weekToDomain($0) }

        guard weeks.count == model.weeks.count else { return nil }

        let snapshots: [RaceSnapshot]
        if let data = model.intermediateRaceSnapshotsData {
            snapshots = (try? JSONDecoder().decode([RaceSnapshot].self, from: data)) ?? []
        } else {
            snapshots = []
        }

        let workouts: [IntervalWorkout]
        if let data = model.workoutsData {
            workouts = (try? JSONDecoder().decode([IntervalWorkout].self, from: data)) ?? []
        } else {
            workouts = []
        }

        var plan = TrainingPlan(
            id: model.id,
            athleteId: model.athleteId,
            targetRaceId: model.targetRaceId,
            createdAt: model.createdAt,
            weeks: weeks,
            intermediateRaceIds: model.intermediateRaceIds,
            intermediateRaceSnapshots: snapshots
        )
        plan.workouts = workouts
        return plan
    }

    static func weekToDomain(_ model: TrainingWeekSwiftDataModel) -> TrainingWeek? {
        guard let phase = TrainingPhase(rawValue: model.phaseRaw) else { return nil }

        let sessions = model.sessions
            .sorted { $0.date < $1.date }
            .compactMap { sessionToDomain($0) }

        guard sessions.count == model.sessions.count else { return nil }

        let phaseFocus: PhaseFocus? = model.phaseFocusRaw.flatMap { PhaseFocus(rawValue: $0) }

        return TrainingWeek(
            id: model.id,
            weekNumber: model.weekNumber,
            startDate: model.startDate,
            endDate: model.endDate,
            phase: phase,
            sessions: sessions,
            isRecoveryWeek: model.isRecoveryWeek,
            targetVolumeKm: model.targetVolumeKm,
            targetElevationGainM: model.targetElevationGainM,
            targetDurationSeconds: model.targetDurationSeconds,
            phaseFocus: phaseFocus
        )
    }

    static func sessionToDomain(_ model: TrainingSessionSwiftDataModel) -> TrainingSession? {
        guard let type = SessionType(rawValue: model.typeRaw),
              let intensity = Intensity(rawValue: model.intensityRaw) else { return nil }

        return TrainingSession(
            id: model.id,
            date: model.date,
            type: type,
            plannedDistanceKm: model.plannedDistanceKm,
            plannedElevationGainM: model.plannedElevationGainM,
            plannedDuration: model.plannedDuration,
            intensity: intensity,
            description: model.sessionDescription,
            nutritionNotes: model.nutritionNotes,
            isCompleted: model.isCompleted,
            isSkipped: model.isSkipped,
            linkedRunId: model.linkedRunId,
            targetHeartRateZone: model.targetHeartRateZone,
            intervalWorkoutId: model.intervalWorkoutId,
            intervalFocus: model.intervalFocus,
            isKeySession: model.isKeySession,
            coachAdvice: model.coachAdvice,
            actualDistanceKm: model.actualDistanceKm,
            actualDurationSeconds: model.actualDurationSeconds,
            actualElevationGainM: model.actualElevationGainM,
            perceivedFeeling: model.perceivedFeelingRaw.flatMap { PerceivedFeeling(rawValue: $0) },
            perceivedExertion: model.perceivedExertion,
            skipReason: model.skipReasonRaw.flatMap { SkipReason(rawValue: $0) }
        )
    }

    // MARK: - To SwiftData

    static func toSwiftData(_ plan: TrainingPlan) -> TrainingPlanSwiftDataModel {
        let weekModels = plan.weeks.map { weekToSwiftData($0) }
        let snapshotsData = try? JSONEncoder().encode(plan.intermediateRaceSnapshots)
        let workoutsData = try? JSONEncoder().encode(plan.workouts)
        return TrainingPlanSwiftDataModel(
            id: plan.id,
            athleteId: plan.athleteId,
            targetRaceId: plan.targetRaceId,
            createdAt: plan.createdAt,
            weeks: weekModels,
            intermediateRaceIds: plan.intermediateRaceIds,
            intermediateRaceSnapshotsData: snapshotsData,
            workoutsData: workoutsData
        )
    }

    static func weekToSwiftData(_ week: TrainingWeek) -> TrainingWeekSwiftDataModel {
        let sessionModels = week.sessions.map { sessionToSwiftData($0) }
        return TrainingWeekSwiftDataModel(
            id: week.id,
            weekNumber: week.weekNumber,
            startDate: week.startDate,
            endDate: week.endDate,
            phaseRaw: week.phase.rawValue,
            sessions: sessionModels,
            isRecoveryWeek: week.isRecoveryWeek,
            targetVolumeKm: week.targetVolumeKm,
            targetElevationGainM: week.targetElevationGainM,
            targetDurationSeconds: week.targetDurationSeconds,
            phaseFocusRaw: week.phaseFocus?.rawValue
        )
    }

    static func sessionToSwiftData(_ session: TrainingSession) -> TrainingSessionSwiftDataModel {
        TrainingSessionSwiftDataModel(
            id: session.id,
            date: session.date,
            typeRaw: session.type.rawValue,
            plannedDistanceKm: session.plannedDistanceKm,
            plannedElevationGainM: session.plannedElevationGainM,
            plannedDuration: session.plannedDuration,
            intensityRaw: session.intensity.rawValue,
            sessionDescription: session.description,
            nutritionNotes: session.nutritionNotes,
            isCompleted: session.isCompleted,
            isSkipped: session.isSkipped,
            linkedRunId: session.linkedRunId,
            targetHeartRateZone: session.targetHeartRateZone,
            intervalWorkoutId: session.intervalWorkoutId,
            intervalFocus: session.intervalFocus,
            isKeySession: session.isKeySession,
            coachAdvice: session.coachAdvice,
            actualDistanceKm: session.actualDistanceKm,
            actualDurationSeconds: session.actualDurationSeconds,
            actualElevationGainM: session.actualElevationGainM,
            perceivedFeelingRaw: session.perceivedFeeling?.rawValue,
            perceivedExertion: session.perceivedExertion,
            skipReasonRaw: session.skipReason?.rawValue
        )
    }
}
