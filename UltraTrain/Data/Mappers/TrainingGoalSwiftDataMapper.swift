import Foundation

enum TrainingGoalSwiftDataMapper {

    static func toDomain(_ model: TrainingGoalSwiftDataModel) -> TrainingGoal {
        TrainingGoal(
            id: model.id,
            period: GoalPeriod(rawValue: model.periodRaw) ?? .weekly,
            targetDistanceKm: model.targetDistanceKm > 0 ? model.targetDistanceKm : nil,
            targetElevationM: model.targetElevationM > 0 ? model.targetElevationM : nil,
            targetRunCount: model.targetRunCount > 0 ? model.targetRunCount : nil,
            targetDurationSeconds: model.targetDurationSeconds > 0 ? model.targetDurationSeconds : nil,
            startDate: model.startDate,
            endDate: model.endDate
        )
    }

    static func toSwiftData(_ goal: TrainingGoal) -> TrainingGoalSwiftDataModel {
        TrainingGoalSwiftDataModel(
            id: goal.id,
            periodRaw: goal.period.rawValue,
            targetDistanceKm: goal.targetDistanceKm ?? 0,
            targetElevationM: goal.targetElevationM ?? 0,
            targetRunCount: goal.targetRunCount ?? 0,
            targetDurationSeconds: goal.targetDurationSeconds ?? 0,
            startDate: goal.startDate,
            endDate: goal.endDate,
            updatedAt: Date.now
        )
    }
}
