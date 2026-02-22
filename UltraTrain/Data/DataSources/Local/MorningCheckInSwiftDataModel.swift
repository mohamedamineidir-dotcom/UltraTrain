import Foundation
import SwiftData

@Model
final class MorningCheckInSwiftDataModel {
    var id: UUID = UUID()
    var date: Date = Date.distantPast
    var perceivedEnergy: Int = 3
    var muscleSoreness: Int = 1
    var mood: Int = 3
    var sleepQualitySubjective: Int = 3
    var notes: String?

    init(
        id: UUID = UUID(),
        date: Date = Date.distantPast,
        perceivedEnergy: Int = 3,
        muscleSoreness: Int = 1,
        mood: Int = 3,
        sleepQualitySubjective: Int = 3,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.perceivedEnergy = perceivedEnergy
        self.muscleSoreness = muscleSoreness
        self.mood = mood
        self.sleepQualitySubjective = sleepQualitySubjective
        self.notes = notes
    }
}
