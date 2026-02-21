import Foundation

enum WorkoutRecipeSwiftDataMapper {

    static func toDomain(_ model: WorkoutRecipeSwiftDataModel) -> WorkoutTemplate? {
        guard let sessionType = SessionType(rawValue: model.sessionTypeRaw),
              let intensity = Intensity(rawValue: model.intensityRaw),
              let category = WorkoutCategory(rawValue: model.categoryRaw) else {
            return nil
        }
        return WorkoutTemplate(
            id: model.id,
            name: model.name,
            sessionType: sessionType,
            targetDistanceKm: model.targetDistanceKm,
            targetElevationGainM: model.targetElevationGainM,
            estimatedDuration: model.estimatedDuration,
            intensity: intensity,
            category: category,
            descriptionText: model.descriptionText,
            isUserCreated: true
        )
    }

    static func toSwiftData(_ template: WorkoutTemplate) -> WorkoutRecipeSwiftDataModel {
        WorkoutRecipeSwiftDataModel(
            id: template.id,
            name: template.name,
            sessionTypeRaw: template.sessionType.rawValue,
            targetDistanceKm: template.targetDistanceKm,
            targetElevationGainM: template.targetElevationGainM,
            estimatedDuration: template.estimatedDuration,
            intensityRaw: template.intensity.rawValue,
            categoryRaw: template.category.rawValue,
            descriptionText: template.descriptionText
        )
    }
}
