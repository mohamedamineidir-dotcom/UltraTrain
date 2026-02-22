import Foundation

enum RaceReflectionMapper {

    static func toDomain(_ model: RaceReflectionSwiftDataModel) -> RaceReflection? {
        guard let pacing = PacingAssessment(rawValue: model.pacingAssessmentRaw),
              let nutrition = NutritionAssessment(rawValue: model.nutritionAssessmentRaw),
              let weather = WeatherImpactLevel(rawValue: model.weatherImpactRaw) else {
            return nil
        }

        return RaceReflection(
            id: model.id,
            raceId: model.raceId,
            completedRunId: model.completedRunId,
            actualFinishTime: model.actualFinishTime,
            actualPosition: model.actualPosition,
            pacingAssessment: pacing,
            pacingNotes: model.pacingNotes,
            nutritionAssessment: nutrition,
            nutritionNotes: model.nutritionNotes,
            hadStomachIssues: model.hadStomachIssues,
            weatherImpact: weather,
            weatherNotes: model.weatherNotes,
            overallSatisfaction: model.overallSatisfaction,
            keyTakeaways: model.keyTakeaways,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ reflection: RaceReflection) -> RaceReflectionSwiftDataModel {
        RaceReflectionSwiftDataModel(
            id: reflection.id,
            raceId: reflection.raceId,
            completedRunId: reflection.completedRunId,
            actualFinishTime: reflection.actualFinishTime,
            actualPosition: reflection.actualPosition,
            pacingAssessmentRaw: reflection.pacingAssessment.rawValue,
            pacingNotes: reflection.pacingNotes,
            nutritionAssessmentRaw: reflection.nutritionAssessment.rawValue,
            nutritionNotes: reflection.nutritionNotes,
            hadStomachIssues: reflection.hadStomachIssues,
            weatherImpactRaw: reflection.weatherImpact.rawValue,
            weatherNotes: reflection.weatherNotes,
            overallSatisfaction: reflection.overallSatisfaction,
            keyTakeaways: reflection.keyTakeaways,
            createdAt: reflection.createdAt,
            updatedAt: Date()
        )
    }
}
