import Foundation

enum MorningCheckInMapper {

    static func toDomain(_ model: MorningCheckInSwiftDataModel) -> MorningCheckIn {
        MorningCheckIn(
            id: model.id,
            date: model.date,
            perceivedEnergy: model.perceivedEnergy,
            muscleSoreness: model.muscleSoreness,
            mood: model.mood,
            sleepQualitySubjective: model.sleepQualitySubjective,
            notes: model.notes
        )
    }

    static func toSwiftData(_ entity: MorningCheckIn) -> MorningCheckInSwiftDataModel {
        MorningCheckInSwiftDataModel(
            id: entity.id,
            date: entity.date,
            perceivedEnergy: entity.perceivedEnergy,
            muscleSoreness: entity.muscleSoreness,
            mood: entity.mood,
            sleepQualitySubjective: entity.sleepQualitySubjective,
            notes: entity.notes
        )
    }
}
