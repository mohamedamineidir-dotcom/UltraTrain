import Foundation

enum TrainingPlanSwiftDataMapper {

    // MARK: - To Domain

    static func toDomain(_ model: TrainingPlanSwiftDataModel) -> TrainingPlan? {
        let weeks = model.weeks
            .sorted { $0.weekNumber < $1.weekNumber }
            .compactMap { weekToDomain($0) }

        guard weeks.count == model.weeks.count else { return nil }

        return TrainingPlan(
            id: model.id,
            athleteId: model.athleteId,
            targetRaceId: model.targetRaceId,
            createdAt: model.createdAt,
            weeks: weeks,
            intermediateRaceIds: model.intermediateRaceIds
        )
    }

    static func weekToDomain(_ model: TrainingWeekSwiftDataModel) -> TrainingWeek? {
        guard let phase = TrainingPhase(rawValue: model.phaseRaw) else { return nil }

        let sessions = model.sessions
            .sorted { $0.date < $1.date }
            .compactMap { sessionToDomain($0) }

        guard sessions.count == model.sessions.count else { return nil }

        return TrainingWeek(
            id: model.id,
            weekNumber: model.weekNumber,
            startDate: model.startDate,
            endDate: model.endDate,
            phase: phase,
            sessions: sessions,
            isRecoveryWeek: model.isRecoveryWeek,
            targetVolumeKm: model.targetVolumeKm,
            targetElevationGainM: model.targetElevationGainM
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
            linkedRunId: model.linkedRunId
        )
    }

    // MARK: - To SwiftData

    static func toSwiftData(_ plan: TrainingPlan) -> TrainingPlanSwiftDataModel {
        let weekModels = plan.weeks.map { weekToSwiftData($0) }
        return TrainingPlanSwiftDataModel(
            id: plan.id,
            athleteId: plan.athleteId,
            targetRaceId: plan.targetRaceId,
            createdAt: plan.createdAt,
            weeks: weekModels,
            intermediateRaceIds: plan.intermediateRaceIds
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
            targetElevationGainM: week.targetElevationGainM
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
            linkedRunId: session.linkedRunId
        )
    }
}
